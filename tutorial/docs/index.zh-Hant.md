<!--
Copyright (c) 2025-2026, Sascha Willems
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# 2026年的Vulkan入門指南

!!! Info

	最後更新時間：2026-02-21：通過VMA實現持久緩衝區映射


## 簡介

[本倉庫](https://github.com/SaschaWillems/HowToVulkan)和配套教程演示了在2026年編寫[Vulkan](https://vulkan.org/)圖形應用程式的方法。目標是利用現代特性簡化Vulkan的使用，並在此過程中創建一些超出基本彩色三角形的內容。

Vulkan發布已近10年，發生了很大變化。1.0版本不得不做出許多妥協，以支援桌面和移動平台上廣泛的GPU。一些初始概念如渲染通道(渲染通道)後來發現並不那麼優化，已被替代方案取代。API日趨成熟，新增了光線追蹤、視訊加速和機器學習等新領域。與API同樣重要的是生態系統，它也發生了很大變化，為我們提供了使用GLSL之外的語言編寫著色器的新選項，以及幫助使用Vulkan的工具。

因此，本教程將以[Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html)為基礎。這使我們可以訪問幾個使Vulkan更易於使用的特性，同時仍支援廣泛的GPU和平台。我們將使用的特性包括：

* [動態渲染](https://www.khronos.org/blog/streamlining-render-passes) - 大大簡化渲染通道設置，這是Vulkan最受批評的領域之一
* [緩衝區設備地址](https://docs.vulkan.org/guide/latest/buffer_device_address.html) - 讓我們可以通過指針訪問緩衝區，而不是通過描述符
* [描述符索引](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html) - 簡化描述符管理，通常被稱為"無綁定"(bindless)
* [同步2](https://docs.vulkan.org/guide/latest/extensions/VK_KHR_synchronization2.html) - 改進同步處理，這是Vulkan最困難的領域之一

簡而言之：在2026年使用Vulkan與在2016年使用Vulkan可能非常不同。這正是我希望通過本教程展示的內容。

!!! Tip

	支援至少Vulkan 1.3的設備列表可以在[這裡](https://vulkan.gpuinfo.org/listdevices.php?apiversion=1.3)找到。


## 目標受眾

本教程專注於編寫實際的Vulkan代碼，並盡可能快地讓程式運行起來（可能在一個下午內完成）。它不會解釋編程、軟體架構、圖形概念或Vulkan的工作原理（詳細）。相反，它經常包含相關資訊的連結，如[Vulkan規範](https://docs.vulkan.org/)。你應該至少具備C/C++和即時圖形概念的基本知識。

## 目標

我們專注於光柵化，Vulkan的其他部分如計算或光線追蹤不在本教程範圍內。在本教程結束時，我們將在螢幕上顯示多個有光照和紋理的3D物件，可以使用滑鼠旋轉它們（[截圖](images/screenshot.png)）。源代碼在一個檔案中，只有幾百行程式碼，沒有抽象層，沒有難以理解的現代C++語言特性或物件導向的把戲。我相信能夠從上到下跟隨源代碼，而不必經過多層抽象，會使它更容易理解。

## 許可證

版權所有 (c) 2025-2026, [Sascha Willems](https://www.saschawillems.de)。本文檔內容根據[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)許可證授權。源代碼列表和檔案根據MIT許可證授權。

## 庫

Vulkan是一個顯式的低級API。為它編寫代碼可能非常冗長。為了專注於有趣的部分，我們將使用以下庫：

* [SDL](https://www.libsdl.org/) - 視窗和輸入（以及本教程中未使用的其他功能）。沒有這樣的庫，我們將不得不編寫大量平台特定的代碼。替代方案包括[GLFW](https://www.glfw.org/)和[SFML](https://www.sfml-dev.org/)。在這些庫中，SDL具有最廣泛的平台支援
* [Volk](https://github.com/zeux/volk) - 元加載器，簡化Vulkan函數的加載
* [VMA](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator) - 簡化記憶體分配的處理。減少了記憶體管理周圍的一些冗長代碼
* [glm](https://github.com/g-truc/glm) - 支援矩陣和向量等功能的數學庫
* [tinyobjloader](https://github.com/tinyobjloader/tinyobjloader) - obj 3D格式的單頭檔案加載器
* [KTX-Software](https://github.com/KhronosGroup/KTX-Software) - Khronos KTX GPU紋理圖像檔案加載器

!!! Tip

	這些庫都不是使用Vulkan所必需的。但它們使使用Vulkan變得更容易，其中一些如VMA和Volk被廣泛使用，即使在商業應用程式中也是如此。

## 編程語言

我們將使用C++ 20，主要因為它的指定初始化器。它們有助於減輕Vulkan的冗長性並提高代碼可讀性。除此之外，我們不會使用現代C++特性，並且使用C Vulkan頭檔案而不是[C++](https://github.com/KhronosGroup/Vulkan-Hpp)頭檔案。除了個人偏好之外，這樣做是為了使本教程盡可能易於理解，包括使用其他編程語言的人。

## 著色語言

Vulkan使用一種稱為[SPIR-V](https://www.khronos.org/spirv/)的中間格式來處理著色器。這將API與實際的著色語言解耦。最初只支援GLSL，但在2026年有更多更好的選擇。其中之一是[Slang](https://github.com/shader-slang)，這也是我們將在本教程中使用的。該語言本身比GLSL更現代，並提供了一些便利的功能。

## Vulkan SDK

雖然開發Vulkan應用程式不是必需的，但[LunarG Vulkan SDK](https://vulkan.lunarg.com/sdk/home)提供了一種方便的方式來安裝常用庫和工具，其中一些在本教程中使用。因此建議安裝它。安裝時，確保選擇可選的GLM、Volk、SDL3和Vulkan Memory Allocator組件。或者，你可以從各自的倉庫下載這些庫，並調整CMakeLists.txt檔案中的包含路徑。

## 驗證層

Vulkan的設計旨在最小化驅動程式開銷。雖然這*可以*導致更好的效能，但它也移除了像OpenGL這樣的API所具有的許多保護措施，並將這一責任交給你。如果你錯誤使用Vulkan，驅動程式可能會崩潰。因此，即使你的應用程式在一個GPU上工作，也不能保證它在其他GPU上也能工作。另一方面，Vulkan規範定義了所有功能的有效用法。並且存在[驗證層](https://github.com/KhronosGroup/Vulkan-ValidationLayers)，這是一個易於使用的工具，可以檢查這些用法。

驗證層可以在代碼中啟用，但更簡單的方法是通過[Vulkan SDK](#vulkan-sdk)提供的[Vulkan配置器GUI](https://vulkan.lunarg.com/doc/view/latest/windows/vkconfig.html)啟用這些層。一旦啟用，任何對API的不當使用都將記錄到我們應用程式的命令列視窗中。

!!! Note

	在使用Vulkan進行開發時，應該始終啟用驗證層。這確保你編寫符合規範的代碼，該代碼可以在其他系統上正常工作。

## 圖形調試器

另一個不可或缺的工具是圖形調試器。類似於Visual Studio等IDE中可用的CPU調試器，這些工具幫助你調試GPU端的運行時問題。一個常用的跨平台和跨供應商的Vulkan支援圖形調試器是[RenderDoc](https://renderdoc.org/)。雖然在本教程中不需要使用這樣的調試器，但如果你想在所學的基礎上繼續學習並在此過程中遇到問題，它將非常有價值。

## 開發環境

我們的構建系統將是[CMake](https://cmake.org/)。類似於我編寫代碼的方法，事情將盡可能保持簡單，同時具有能夠使用各種C++編譯器和IDE遵循本教程的額外好處。

要為你的C++ IDE創建構建檔案，請在項目的源資料夾中運行CMake，如下所示：

```bash
cmake -B build -G "Visual Studio 17 2022"
```

這將在`build`資料夾中寫入Visual Studio 2022解決方案檔案。作為命令列的替代方案，你可以使用[cmake-gui](https://cmake.org/cmake/help/latest/manual/cmake-gui.1.html)。生成器(-G)取決於你的IDE，你可以在[這裡](https://cmake.org/cmake/help/latest/manual/cmake-generators.7.html)找到這些生成器的列表。

## 源代碼

現在一切都已經正確設置，我們可以開始深入研究代碼了。以下章節將從上到下引導你了解[主源檔案](https://github.com/SaschaWillems/HowToVulkan/blob/main/source/main.cpp)。

!!! Warning

	本文檔中省略了一些不太有趣的初始化、聲明和樣板代碼。建議在進行本教程時同時打開主源檔案。

## 實例設置

我們需要的第一件事是Vulkan實例。它將應用程式連接到Vulkan，因此是後續一切的基礎。

設置實例包括傳遞關於你的應用程式的資訊：

```cpp
VkApplicationInfo appInfo{
	.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
	.pApplicationName = "How to Vulkan",
	.apiVersion = VK_API_VERSION_1_3
};
```

最重要的是`apiVersion`，它告訴Vulkan我們要使用Vulkan 1.3。使用更高的API版本可以讓我們開箱即用地獲得更多功能，否則必須通過擴展來使用這些功能。[Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html)得到廣泛支援，並添加了許多使Vulkan更易於使用的核心功能。`pApplicationName`可用於標識你的應用程式。

!!! Info

	你會經常看到的一個結構成員是`sType`。驅動程式需要知道它要處理什麼類型的結構，而由於Vulkan是一個C-API，除了通過結構成員指定之外沒有其他方法。

實例還需要知道你想使用的擴展。顧名思義，這些用於擴展API。由於實例創建（以及其他一些事情）是平台特定的，實例需要知道你想使用哪些平台特定的擴展。例如，對於Windows，你會使用[VK_KHR_win32_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_win32_surface.html)，對於Android則使用[VK_KHR_android_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_android_surface.html)，其他平台也是如此。

!!! Note

	Vulkan中有兩種擴展類型。實例擴展和設備擴展。前者主要是全局的，通常是與GPU無關的平台特定擴展，後者基於你的GPU的能力。

這意味著我們不得不編寫平台特定的代碼。**但是**，使用像SDL這樣的庫，我們不必這樣做，而是向SDL請求平台特定的實例擴展：

```cpp
uint32_t instanceExtensionsCount{ 0 };
char const* const* instanceExtensions{ SDL_Vulkan_GetInstanceExtensions(&instanceExtensionsCount) };
```

所以不再需要擔心平台特定的事情。有了應用程式資訊和所需的擴展設置，我們可以創建我們的實例：

```cpp
VkInstanceCreateInfo instanceCI{
	.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
	.pApplicationInfo = &appInfo,
	.enabledExtensionCount = instanceExtensionsCount,
	.ppEnabledExtensionNames = instanceExtensions,
};
chk(vkCreateInstance(&instanceCI, nullptr, &instance));
```

這非常簡單。我們傳遞我們的應用程式資訊以及SDL給我們的實例擴展的名稱和數量（針對我們編譯的平台）。調用[`vkCreateInstance`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateInstance.html)創建我們的實例。

!!! Tip

	大多數Vulkan函數可能以不同方式失敗，並返回[`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html)值。我們使用一個名為`chk`的小內聯函數來檢查該返回代碼，如果出錯則退出應用程式。在實際應用程式中，你應該進行更複雜的錯誤處理。

## 設備選擇

現在我們需要選擇要用於渲染的設備。雖然這不常見，但在單個系統中可能有多個支援Vulkan的設備。例如，如果你安裝了多個GPU，或者你有整合顯卡和獨立顯卡：

!!! Info

	在處理Vulkan時，一個常用的術語是實現。這指的是實現Vulkan API的東西。通常是你GPU的驅動程式，但也可能是基於CPU的軟體實現。為了保持簡單，我們將在本教程的其餘部分使用術語GPU。

為此，我們獲取所有支援Vulkan的可用物理設備的列表：

```cpp
uint32_t deviceCount{ 0 };
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr));
std::vector<VkPhysicalDevice> devices(deviceCount);
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data()));
```

在第二次調用[`vkEnumeratePhysicalDevices`](https://docs.vulkan.org/refpages/latest/refpages/source/vkEnumeratePhysicalDevices.html)之後，我們有了一個包含所有可用支援Vulkan的設備的列表。

!!! Info

	必須調用兩次返回某種列表的函數在Vulkan C-API中很常見。第一次調用將返回元素數量，然後用於正確調整結果列表的大小。第二次調用然後填充實際的結果列表。

由於大多數系統只有一個設備，我們只是實現一種簡單且可選的方法，通過將所需的設備索引作為命令列參數傳遞來選擇設備：

```cpp
uint32_t deviceIndex{ 0 };
if (argc > 1) {
	deviceIndex = std::stoi(argv[1]);
	assert(deviceIndex < deviceCount);
}
```

我們還希望顯示所選設備的資訊。為此，我們調用[`vkGetPhysicalDeviceProperties2`](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceProperties2.html)並將設備名稱輸出到控制台：

```cpp
VkPhysicalDeviceProperties2 deviceProperties{ .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2 };
vkGetPhysicalDeviceProperties2(devices[deviceIndex], &deviceProperties);
std::cout << "Selected device: " << deviceProperties.properties.deviceName <<  "
";
```

!!! Info

	你可能已經注意到`VkPhysicalDeviceProperties2`和`vkGetPhysicalDeviceProperties2`的後綴是`2`。這樣做是為了[解決](https://docs.vulkan.org/spec/latest/appendices/legacy.html)以前版本的缺點。修復原始函數和結構不是一個選項，因為那會破壞API兼容性。

## 佇列

在Vulkan中，工作不是直接提交到設備，而是提交到佇列。佇列抽象了對硬體（圖形、計算、傳輸、視訊等）的訪問。它們組織在佇列族中，每個族描述一組具有共同功能的佇列。可用的佇列類型在GPU之間有所不同。由於我們只進行圖形操作，我們只需要找到一個支援圖形的佇列族。這是通過檢查[`VK_QUEUE_GRAPHICS_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkQueueFlagBits.html)標誌來完成的：

```cpp
uint32_t queueFamilyCount{ 0 };
vkGetPhysicalDeviceQueueFamilyProperties(devices[deviceIndex], &queueFamilyCount, nullptr);
std::vector<VkQueueFamilyProperties> queueFamilies(queueFamilyCount);
vkGetPhysicalDeviceQueueFamilyProperties(devices[deviceIndex], &queueFamilyCount, queueFamilies.data());
uint32_t queueFamily{ 0 };
for (size_t i = 0; i < queueFamilies.size(); i++) {
	if (queueFamilies[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
		queueFamily = i;
		break;
	}
}
```

由於我們要使用該圖形佇列[呈現](#present-image)某些內容到螢幕，我們還檢查該佇列是否支援呈現：

```cpp
chk(SDL_Vulkan_GetPresentationSupport(instance, devices[deviceIndex], queueFamily));
```

!!! Tip

	沒有支援圖形的佇列族的設備在現實中非常罕見。此外，在大多數設備上，第一個佇列族支援圖形、計算和呈現。像我們上面那樣檢查這仍然是一個好習慣，特別是當你想使用其他佇列類型如計算時。如果你遇到圖形、計算和/或呈現需要不同佇列族的設備，你必須在這些佇列之間進行額外的同步。

對於我們的下一步，我們需要使用[`VkDeviceQueueCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkDeviceQueueCreateInfo.html)來引用該佇列族。可以從同一族請求多個佇列，但我們不需要那樣做。這就是為什麼我們需要在`pQueuePriorities`中指定優先級（在我們的情況下只有一個）。對於來自同一族的多個佇列，驅動程式可能會使用該資訊來優先處理工作：

```cpp
const float qfpriorities{ 1.0f };
VkDeviceQueueCreateInfo queueCI{
	.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
	.queueFamilyIndex = queueFamily,
	.queueCount = 1,
	.pQueuePriorities = &qfpriorities
};
```

## 設備設置

現在我們有了到Vulkan庫的連接，選擇了一個物理設備，並且知道我們要使用哪個佇列族，我們需要獲取GPU的句柄。這在Vulkan中稱為**設備**。Vulkan區分物理設備和邏輯設備。前者表示實際的設備（通常是GPU），後者表示對該設備的Vulkan實現的句柄，應用程式將與之交互。

設備創建的一個重要部分是請求我們要使用的特性和擴展。我們的實例是使用Vulkan 1.3作為基礎創建的，這幾乎給了我們想要使用的所有特性。所以我們只需要請求[`VK_KHR_swapchain`](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_swapchain.html)擴展，以便能夠向螢幕呈現某些內容：

```cpp
const std::vector<const char*> deviceExtensions{ VK_KHR_SWAPCHAIN_EXTENSION_NAME };
```

!!! Tip

	Vulkan頭檔案為所有擴展定義了常量，如`VK_KHR_SWAPCHAIN_EXTENSION_NAME`。你可以使用這些常量而不是將它們的名稱寫為字串。這有助於避免擴展名稱中的拼寫錯誤。

使用Vulkan 1.3作為基礎，我們可以使用[前面](#about)提到的特性，而不必求助於擴展。使用擴展時，需要更多的代碼，並且如果擴展不存在，需要檢查和回退路徑。對於核心特性，我們可以簡單地啟用它們：

```cpp
VkPhysicalDeviceVulkan12Features enabledVk12Features{
	.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
	.descriptorIndexing = true,
	.shaderSampledImageArrayNonUniformIndexing = true,
	.descriptorBindingVariableDescriptorCount = true,
	.runtimeDescriptorArray = true,
	.bufferDeviceAddress = true
};
const VkPhysicalDeviceVulkan13Features enabledVk13Features{
	.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES,
	.pNext = &enabledVk12Features,
	.synchronization2 = true,
	.dynamicRendering = true,
};
const VkPhysicalDeviceFeatures enabledVk10Features{
	.samplerAnisotropy = VK_TRUE
};
```

`shaderSampledImageArrayNonUniformIndexing`、`descriptorBindingVariableDescriptorCount`和`runtimeDescriptorArray`與描述符索引相關，其餘名稱與實際特性匹配。我們還啟用了[各向異性過濾](https://docs.vulkan.org/refpages/latest/refpages/source/VkPhysicalDeviceFeatures.html#_members)以獲得更好的紋理過濾。

!!! Info

	你將經常看到的另一個Vulkan結構成員是`pNext`。這可以用於創建一個傳遞給函數調用的結構鏈表。驅動程式然後使用該列表中每個結構的`sType`成員來識別所述結構的類型。

有了所有東西，我們可以創建一個邏輯設備，其中包含我們要使用的核心特性、擴展和佇列族：

```cpp
VkDeviceCreateInfo deviceCI{
	.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
	.pNext = &enabledVk13Features,
	.queueCreateInfoCount = 1,
	.pQueueCreateInfos = &queueCI,
	.enabledExtensionCount = static_cast<uint32_t>(deviceExtensions.size()),
	.ppEnabledExtensionNames = deviceExtensions.data(),
	.pEnabledFeatures = &enabledVk10Features
};
chk(vkCreateDevice(devices[deviceIndex], &deviceCI, nullptr, &device));
```

我們還需要一個佇列來提交我們的圖形命令，現在可以從我們剛創建的設備中請求它：

```cpp
vkGetDeviceQueue(device, queueFamily, 0, &queue);
```

## 設置VMA

Vulkan是一個顯式API，這也適用於記憶體管理。如庫列表中所述，我們將使用[Vulkan記憶體分配器(VMA)](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator)來大大簡化這一領域。

VMA提供了一個用於分配記憶體的分配器。這需要為你的項目設置一次。為此，我們傳入一些常用Vulkan函數的指針、我們的Vulkan實例和設備，我們還啟用對緩衝區設備地址的支援(`flags`)：

```cpp
VmaVulkanFunctions vkFunctions{
	.vkGetInstanceProcAddr = vkGetInstanceProcAddr,
	.vkGetDeviceProcAddr = vkGetDeviceProcAddr,
	.vkCreateImage = vkCreateImage
};
VmaAllocatorCreateInfo allocatorCI{
	.flags = VMA_ALLOCATOR_CREATE_BUFFER_DEVICE_ADDRESS_BIT,
	.physicalDevice = devices[deviceIndex],
	.device = device,
	.pVulkanFunctions = &vkFunctions,
	.instance = instance
};
chk(vmaCreateAllocator(&allocatorCI, &allocator));
```

!!! Tip

	VMA也使用[`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html)返回代碼，我們可以使用相同的`chk`函數來檢查VMA的函數結果。

## 視窗和表面

要在Vulkan中"繪製"某些內容（正確的術語應該是"呈現圖像"，稍後會詳細介紹），我們需要一個表面。大多數時候，表面是從視窗獲取的。創建這兩者都是平台特定的，如[實例章節](#instance-setup)中所述。因此理論上，這*將*要求我們為所有要支援的平台（Windows、Linux、Android等）編寫不同的代碼路徑。

但這正是像SDL這樣的庫發揮作用的地方。它們為我們處理所有平台特定的細節，使這部分變得非常簡單。

!!! Tip

	像SDL、GLFW和SFML這樣的庫也處理其他平台特定的功能，如輸入、音訊和網絡（程度不同）。

首先，我們創建一個支援Vulkan的視窗：

```cpp
SDL_Window* window = SDL_CreateWindow("How to Vulkan", 1280u, 720u, SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE);
```

然後為該視窗請求一個Vulkan表面：

```cpp
chk(SDL_Vulkan_CreateSurface(window, instance, nullptr, &surface));
```

對於以下章節，我們需要知道我們剛創建的表面的屬性，所以我們通過[`vkGetPhysicalDeviceSurfaceCapabilitiesKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceSurfaceCapabilitiesKHR.html)獲取它們並存儲以備將來參考：

```cpp
VkSurfaceCapabilitiesKHR surfaceCaps{};
chk(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(devices[deviceIndex], surface, &surfaceCaps));
```

## 交換鏈

要向表面（在我們的情況下是視窗）視覺呈現某些內容，我們需要創建一個交換鏈。它基本上是一系列圖像，存儲顏色資訊，你將其排隊到操作系統的呈現引擎。[`VkSwapchainCreateInfoKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkSwapchainCreateInfoKHR.html)非常廣泛，需要一些解釋。

```cpp
const VkFormat imageFormat{ VK_FORMAT_B8G8R8A8_SRGB };
VkSwapchainCreateInfoKHR swapchainCI{
	.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
	.surface = surface,
	.minImageCount = surfaceCaps.minImageCount,
	.imageFormat = imageFormat,
	.imageColorSpace = VK_COLORSPACE_SRGB_NONLINEAR_KHR,
	.imageExtent{ .width = surfaceCaps.currentExtent.width, .height = surfaceCaps.currentExtent.height },
	.imageArrayLayers = 1,
	.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
	.preTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR,
	.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
	.presentMode = VK_PRESENT_MODE_FIFO_KHR
};
chk(vkCreateSwapchainKHR(device, &swapchainCI, nullptr, &swapchain));
```

我們使用4分量顏色格式`VK_FORMAT_B8G8R8A8_SRGB`和非線性sRGB[色彩空間](https://docs.vulkan.org/refpages/latest/refpages/source/VkColorSpaceKHR.html)`VK_COLORSPACE_SRGB_NONLINEAR_KHR`。這種組合保證在任何地方都可用。不同的組合需要檢查支援。`minImageCount`將是我們從交換鏈獲得的最小圖像數量。這個值在GPU之間有所不同，這就是為什麼我們使用之前從表面請求的資訊。`presentMode`定義了圖像呈現到螢幕的方式。[`VK_PRESENT_MODE_FIFO_KHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPresentModeKHR.html#)是一個v-sync模式，是保證在任何地方都可用的唯一模式。

!!! Note

	這裡顯示的交換鏈設置是最低限度。在實際應用程式中，這部分可能會相當複雜，因為你可能需要根據用戶設置進行調整。一個例子是HDR支援的設備，你需要使用不同的圖像格式和色彩空間。

交換鏈的一個特殊之處在於它的圖像不屬於應用程式，而是屬於交換鏈。因此，我們不會顯式創建這些圖像，而是從交換鏈請求它們。這將給我們至少與`minImageCount`設置的圖像一樣多的圖像：

```cpp
uint32_t imageCount{ 0 };
chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, nullptr));
swapchainImages.resize(imageCount);
chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, swapchainImages.data()));
swapchainImageViews.resize(imageCount);
```

## 深度附件

由於我們渲染三維物件，我們希望確保它們正確顯示，無論你從什麼角度觀察它們，或者它們的三角形以什麼順序進行光柵化。這是通過[深度測試](https://docs.vulkan.org/spec/latest/chapters/fragops.html#fragops-depth)完成的，要使用它，我們需要有一個深度附件。

首先，我們需要使用[vkGetPhysicalDeviceFormatProperties2](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceFormatProperties2.html)檢查當前GPU上實際可用的深度格式：

```cpp
std::vector<VkFormat> depthFormatList{ VK_FORMAT_D32_SFLOAT_S8_UINT, VK_FORMAT_D24_UNORM_S8_UINT };
VkFormat depthFormat{ VK_FORMAT_UNDEFINED };
for (VkFormat& format : depthFormatList) {
	VkFormatProperties2 formatProperties{ .sType = VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2 };
	vkGetPhysicalDeviceFormatProperties2(devices[deviceIndex], format, &formatProperties);
	if (formatProperties.formatProperties.optimalTilingFeatures & VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT) {
		depthFormat = format;
		break;
	}
}
```

!!! Note

	Vulkan規範[保證]((https://docs.vulkan.org/spec/latest/chapters/formats.html#features-required-format-support))某些格式和用途組合在所有設備上得到支援。其中一個保證是對於深度格式，其中`VK_FORMAT_D32_SFLOAT_S8_UINT`或`VK_FORMAT_D24_UNORM_S8_UINT`必須被支援用作深度附件。

深度圖像的屬性然後在[`VkImageCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageCreateInfo.html)結構中定義。其中一些類似於在交換鏈創建中找到的那些：

```
VkImageCreateInfo depthImageCI{
	.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
	.imageType = VK_IMAGE_TYPE_2D,
	.format = depthFormat,
	.extent{.width = window.getSize().x, .height = window.getSize().y, .depth = 1 },
	.mipLevels = 1,
	.arrayLayers = 1,
	.samples = VK_SAMPLE_COUNT_1_BIT,
	.tiling = VK_IMAGE_TILING_OPTIMAL,
	.usage = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,
	.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
};
```
圖像是2D的，並使用支援深度的格式。我們不需要多個mip級別或層。使用最佳平鋪與[`VK_IMAGE_TILING_OPTIMAL`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageTiling.html)確保圖像以最適合GPU的格式存儲。我們還需要聲明我們對圖像的期望用途，即[`VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageUsageFlagBits.html)，因為我們將其用作渲染輸出的深度附件（稍後會詳細介紹）。初始佈局定義圖像的內容，我們不必關心，所以我們將其設置為[`VK_IMAGE_LAYOUT_UNDEFINED`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html)。

這也是我們第一次使用VMA在Vulkan中分配某些東西。Vulkan中緩衝區和圖像的記憶體分配很冗長但通常非常相似。使用VMA，我們可以省去很多這些內容。VMA還處理選擇正確的記憶體類型和用途標誌，否則需要大量代碼才能正確完成。

```cpp
VmaAllocationCreateInfo allocCI{
	.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
chk(vmaCreateImage(allocator, &depthImageCI, &allocCI, &depthImage, &depthImageAllocation, nullptr));
```

使VMA如此便利的一點是[`VMA_MEMORY_USAGE_AUTO`](https://gpuopen-librariesandsdks.github.io/VulkanMemoryAllocator/html/choosing_memory_type.html)。這個用途標誌將讓VMA根據你為分配和/或緩衝區創建資訊傳入的其他值自動選擇所需的用途標誌。在某些情況下，你最好顯式聲明用途標誌，但在大多數情況下，自動標誌是完美的選擇。`VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT`標誌告訴VMA為此資源創建單獨的記憶體分配，這被推薦用於例如大型圖像附件。

!!! Tip

	我們只需要一個圖像，即使我們在其他地方進行雙緩衝。這是因為圖像只被GPU訪問，而GPU一次只能寫入一個深度圖像。這與CPU和GPU共享的資源不同，但稍後會詳細介紹。

Vulkan中的圖像不是直接訪問的，而是通過[視圖](https://docs.vulkan.org/spec/latest/chapters/resources.html#VkImageView)，這是編程中的一個常見概念。這增加了靈活性，並允許對同一圖像進行不同的訪問模式。

```cpp
VkImageViewCreateInfo depthViewCI{
	.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
	.image = depthImage,
	.viewType = VK_IMAGE_VIEW_TYPE_2D,
	.format = depthFormat,
	.subresourceRange{ .aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT, .levelCount = 1, .layerCount = 1 }
};
chk(vkCreateImageView(device, &depthViewCI, nullptr, &depthImageView));
```

我們需要一個視圖來訪問我們剛創建的圖像，並且我們希望將其作為2D視圖訪問。`subresourceRange`指定我們希望通過此視圖訪問圖像的哪一部分。對於具有多個層或(mip)級別的圖像，你可以為任何這些部分創建單獨的圖像視圖，並以不同方式訪問圖像。`aspectMask`指的是我們希望通過視圖訪問的圖像的方面。這可以是顏色、模板或（在我們的情況下）圖像的深度部分。

有了圖像和圖像視圖的創建，我們的深度附件現在準備好用於稍後的渲染。

## 加載網格

從Vulkan的角度來看，繪製單個三角形或具有數千個三角形的複雜網格在技術上沒有區別。兩者都導致GPU將從中讀取數據的某種緩衝區。GPU不在乎數據來自哪裡。我們可以從顯示具有硬編碼頂點數據的單個三角形開始，但對於學習體驗來說，加載實際的3D物件要好得多。這是我們的下一步。

有很多格式可用於存儲3D模型。例如，[glTF](https://www.khronos.org/Gltf)提供了許多功能，並以類似於Vulkan的方式可擴展。但我們想保持簡單，所以我們將使用[Wavefront .obj格式](https://en.wikipedia.org/wiki/Wavefront_.obj_file)代替。就3D格式而言，沒有比這更簡單的了。並且它被許多工具支援，如[Blender](https://www.blender.org/)。

首先，我們聲明一個用於我們應用程式中計劃使用的頂點數據的結構。這是頂點位置、頂點法線（用於光照）和紋理坐標。這些通常簡稱為[uv](https://en.wikipedia.org/wiki/UV_mapping)：

```cpp
struct Vertex {
	glm::vec3 pos;
	glm::vec3 normal;
	glm::vec2 uv;
};
```

我們使用[tinyobjloader庫](https://github.com/tinyobjloader/tinyobjloader)來加載.obj檔案。它進行所有解析，並為我們提供對該檔案中包含的數據的結構化訪問：

```cpp
// 網格數據
tinyobj::attrib_t attrib;
std::vector<tinyobj::shape_t> shapes;
std::vector<tinyobj::material_t> materials;
chk(tinyobj::LoadObj(&attrib, &shapes, &materials, nullptr, nullptr, "assets/suzanne.obj"));
```

成功調用`LoadObj`後，我們可以訪問存儲在所選.obj檔案中的頂點數據。`attrib`包含頂點數據的線性陣列，`shapes`包含對該數據的索引。`materials`不會被使用，我們將進行自己的著色。

!!! Warning

	.obj格式有點過時，並不完全符合現代3D管線。其中一個方面是頂點數據的索引。由於.obj檔案的結構方式，我們最終每個頂點有一個索引，這限制了索引渲染的有效性。在實際應用程式中，你會使用與索引渲染良好配合的格式，如glTF。

我們將使用交錯頂點屬性。交錯意味著，在記憶體中，對於每個頂點，位置的3個浮點數後面是法線向量的3個浮點數（用於光照），然後是紋理坐標的2個浮點數。

為了使這工作，我們需要轉換tinyobj提供的頂點、法線和紋理坐標值數據：

```cpp
const VkDeviceSize indexCount{shapes[0].mesh.indices.size()};
std::vector<Vertex> vertices{};
std::vector<uint16_t> indices{};
// 加載頂點和索引數據
for (auto& index : shapes[0].mesh.indices) {
	Vertex v{
		.pos = { attrib.vertices[index.vertex_index * 3], -attrib.vertices[index.vertex_index * 3 + 1], attrib.vertices[index.vertex_index * 3 + 2] },
		.normal = { attrib.normals[index.normal_index * 3], -attrib.normals[index.normal_index * 3 + 1], attrib.normals[index.normal_index * 3 + 2] },
		.uv = { attrib.texcoords[index.texcoord_index * 2], 1.0 - attrib.texcoords[index.texcoord_index * 2+ 1] }
	};
	vertices.push_back(v);
	indices.push_back(indices.size());
}
```

!!! Tip

	位置和法線的y軸值以及紋理坐標的v軸被翻轉。這是為了適應Vulkan的坐標系統。否則，模型和紋理圖像將會顯示為倒置。

有了以交錯方式存儲的數據，我們現在可以將其上傳到GPU。為此，我們需要創建一個將保存頂點和索引數據的緩衝區：

```cpp
VkDeviceSize vBufSize{ sizeof(Vertex) * vertices.size() };
VkDeviceSize iBufSize{ sizeof(uint16_t) * indices.size() };
VkBufferCreateInfo bufferCI{
	.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
	.size = vBufSize + iBufSize,
	.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_INDEX_BUFFER_BIT
};
```

我們不為頂點和索引使用單獨的緩衝區，而是將兩者放在同一個緩衝區中。因此，緩衝區的`size`是從頂點和索引向量的大小計算出來的。緩衝區[`usage`](https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html)位掩碼組合`VK_BUFFER_USAGE_VERTEX_BUFFER_BIT`和`VK_BUFFER_USAGE_INDEX_BUFFER_BIT`向驅動程式信號表示預期用途。

類似於之前創建圖像，我們使用VMA分配用於存儲頂點和索引數據的緩衝區：

```cpp
VmaAllocationCreateInfo vBufferAllocCI{
	.flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT | VMA_ALLOCATION_CREATE_MAPPED_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
VmaAllocationInfo vBufferAllocInfo{};
chk(vmaCreateBuffer(allocator, &bufferCI, &vBufferAllocCI, &vBuffer, &vBufferAllocation, &vBufferAllocInfo));
```

我們再次使用`VMA_MEMORY_USAGE_AUTO`讓VMA為緩衝區選擇正確的用途標誌。這裡使用的特定`flags`組合`VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT`和`VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT`確保我們獲得位於GPU上（在VRAM中）並且可以被主機訪問的記憶體類型。雖然可以將頂點和索引存儲在CPU記憶體中，但GPU對它們的訪問會慢得多。早期，CPU可訪問的VRAM記憶體類型只在具有統一記憶體架構的系統上可用，如移動設備或整合GPU。但感謝[(Re)BAR/SAM](https://en.wikipedia.org/wiki/PCI_configuration_space#Resizable_BAR)，即使是獨立GPU現在也可以將大部分VRAM映射到主機地址空間，並使其可以通過CPU訪問。

!!! Note

	沒有這個，我們將不得不在主機上創建所謂的"暫存"緩衝區，將數據複製到該緩衝區，然後通過命令緩衝區提交從暫存到GPU端緩衝區的緩衝區複製。這將需要更多的代碼。

`VMA_ALLOCATION_CREATE_MAPPED_BIT`為我們提供一個持久映射的緩衝區，這使我們可以直接將數據複製到VRAM：

```cpp
memcpy(vBufferAllocInfo.pMappedData, vertices.data(), vBufSize);
memcpy(((char*)vBufferAllocInfo.pMappedData) + vBufSize, indices.data(), iBufSize);
```

## CPU和GPU並行

在圖形密集的應用程式中，CPU主要用於向GPU提供工作。當OpenGL發明時，計算機只有一個帶有單個核心的CPU。但今天，即使是移動設備也有多個核心，Vulkan給了我們更顯式的控制權，可以控制工作如何分布在這些核心和GPU之間。

這使我們可以在可能的地方讓CPU和GPU並行工作。因此，當GPU仍然忙時，我們已經可以開始在CPU上創建下一個"工作包"。天真的方法是讓GPU總是等待CPU（反之亦然），但這會扼殺任何並行的機會。

!!! Tip

	記住這一點有助於理解Vulkan中為什麼存在[命令緩衝區](#command-buffers)以及為什麼我們複製某些資源。

這樣做的一個先決條件是乘以CPU和GPU共享的資源。這樣，CPU可以開始更新資源*n+1*，而GPU仍在使用資源*n*。這基本上是雙（或多）緩衝，在Vulkan中通常稱為"飛行中的幀"。

雖然理論上我們可以有多個飛行中的幀，但每個添加的飛行中的幀也會增加延遲。因此，通常你最多有2或3個飛行中的幀。我們在代碼的最頂部定義這個：

```cpp
constexpr uint32_t maxFramesInFlight{ 2 };
```

並用它來調整所有CPU和GPU共享的資源：

```cpp
std::array<ShaderDataBuffer, maxFramesInFlight> shaderDataBuffers;
std::array<VkCommandBuffer, maxFramesInFlight> commandBuffers;
```

!!! Note

	飛行中的幀的概念只適用於CPU和GPU共享的資源。僅由GPU使用的資源不必乘以。這適用於例如圖像。

## 著色數據緩衝區

我們還希望向我們的[著色器](#the-shader)傳遞可以在CPU端更改的值，例如來自用戶輸入。為此，我們將創建可以由CPU寫入並由GPU讀取的緩衝區。這些緩衝區中的數據在繪製調用的所有著色器調用中保持恆定（統一）。這是對GPU的重要保證。

我們希望傳遞的數據存儲在單個結構中並連續佈局，這樣我們可以輕鬆地將其複製到匹配的GPU結構：

```cpp
struct ShaderData {
	glm::mat4 projection;
	glm::mat4 view;
	glm::mat4 model[3];
	glm::vec4 lightPos{ 0.0f, -10.0f, 10.0f, 0.0f };
	uint32_t selected{1};
} shaderData{};
```

!!! Warning

	重要的是在CPU端和GPU端匹配結構佈局。根據使用的數據類型和排列，佈局可能看起來相同，但由於著色語言如何對齊結構成員，實際上會有所不同。避免這種情況的一種方法，除了手動對齊或填充結構，是使用Vulkan的[VK_EXT_scalar_block_layout](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_scalar_block_layout.html)或相應的Vulkan 1.2核心特性（兩者都是可選的）。


如果我們使用較舊的Vulkan版本，我們現在*將*不得不處理描述符，這是Vulkan的一個基本但部分受限且難以管理的部分。

但通過使用Vulkan 1.3的[緩衝區設備地址](https://docs.vulkan.org/guide/latest/buffer_device_address.html)特性，我們可以免去描述符（對於緩衝區）。我們不必通過描述符訪問它們，而是可以在著色器中使用指針語法通過地址訪問緩衝區。這不僅使事情更容易理解，還減少了一些耦合，並需要更少的代碼。

如[上一章](#cpu-and-gpu-parallelism)所述，我們為最大飛行中的幀數創建一個著色數據緩衝區。這樣，我們可以在CPU上更新一個緩衝區，而GPU從另一個緩衝區讀取。這確保我們不會遇到任何讀/寫危險，即CPU開始更新值而GPU仍在讀取它們：

```cpp
for (auto i = 0; i < maxFramesInFlight; i++) {
	VkBufferCreateInfo uBufferCI{
		.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
		.size = sizeof(ShaderData),
		.usage = VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT
	};
	VmaAllocationCreateInfo uBufferAllocCI{
		.flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT | VMA_ALLOCATION_CREATE_MAPPED_BIT,
		.usage = VMA_MEMORY_USAGE_AUTO
	};
	chk(vmaCreateBuffer(allocator, &uBufferCI, &uBufferAllocCI, &shaderDataBuffers[i].buffer, &shaderDataBuffers[i].allocation, &shaderDataBuffers[i].allocationInfo));
```

創建這些緩衝區類似於為我們的網格創建頂點/索引緩衝區。創建資訊結構聲明我們希望通過其設備地址(`VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT`)訪問此緩衝區。緩衝區大小必須（至少）與我們的CPU數據結構匹配。我們再次使用VMA處理分配，使用與頂點/索引緩衝區相同的標誌，以確保我們獲得一個可以被CPU和GPU訪問的緩衝區。使用`VMA_ALLOCATION_CREATE_MAPPED_BIT`標誌確保緩衝區被持久映射，並在`VmaAllocationInfo`結構中為我們提供指向緩衝區的指針。與較舊的API不同，這在Vulkan中是完全沒問題的，並使稍後更新緩衝區更容易，因為我們可以保持指向緩衝區（記憶體）的永久指針。

!!! Tip

	與較大的靜態緩衝區不同，用於向著色器傳遞少量數據的緩衝區不必存儲在GPU的VRAM中。雖然我們仍然向VMA請求這樣的記憶體類型，但回退到CPU端記憶體不會是問題。

```cpp
	VkBufferDeviceAddressInfo uBufferBdaInfo{
		.sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO,
		.buffer = shaderDataBuffers[i].buffer
	};
	shaderDataBuffers[i].deviceAddress = vkGetBufferDeviceAddress(device, &uBufferBdaInfo);
}
```

為了能夠在我們的著色器中訪問緩衝區，然後我們獲取其設備地址並存儲它以備將來訪問。

## 同步物件

Vulkan非常顯式的另一個領域是[同步](https://docs.vulkan.org/spec/latest/chapters/synchronization.html)。其他API如OpenGL為我們隱式地做了這些。但在這裡，我們需要確保對GPU資源的訪問得到適當保護，以避免任何寫/讀危險，這可能由於例如CPU開始寫入GPU仍在使用的記憶體而發生。這有點類似於在CPU上進行多線程，但更複雜，因為我們需要使這在CPU和GPU之間工作，這兩者都是非常不同類型的處理單元，並且在GPU本身上。

!!! Warning

	在Vulkan中正確處理同步可能非常困難，特別是因為錯誤或缺失的同步可能不會在所有GPU或所有情況下都可見。有時它只在低幀率或移動設備上顯示。[驗證層](#validation-layers)包括一種使用同步驗證預設檢查這種情況的方法。確保偶爾啟用它並檢查報告的任何危險。

我們將在本教程中使用不同的同步方式：

* [柵欄](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-fences)用於從GPU向CPU信號工作完成。當我們需要確保GPU和CPU都使用的資源可以在CPU上修改時，我們使用它們。
* [二元信號量](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-semaphores)用於控制GPU端（僅）對資源的訪問。我們使用它們確保諸如呈現之類的事情的正確排序。
* [管線柵欄](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-pipeline-barriers)用於控制GPU佇列中的資源訪問。我們使用它們進行圖像的佈局轉換。

柵欄和二元信號量是我們必須創建和存儲的物件，柵欄則作為命令發布，將在稍後討論：

```cpp
VkSemaphoreCreateInfo semaphoreCI{
	.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO
};
VkFenceCreateInfo fenceCI{
	.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
	.flags = VK_FENCE_CREATE_SIGNALED_BIT
};
for (auto i = 0; i < maxFramesInFlight; i++) {
	chk(vkCreateFence(device, &fenceCI, nullptr, &fences[i]));
	chk(vkCreateSemaphore(device, &semaphoreCI, nullptr, &presentSemaphores[i]));
}
renderSemaphores.resize(swapchainImages.size());
for (auto& semaphore : renderSemaphores) {
	chk(vkCreateSemaphore(device, &semaphoreCI, nullptr, &semaphore));
}
```

創建這些物件沒有很多選項。通過設置`VK_FENCE_CREATE_SIGNALED_BIT`標誌，柵欄將在信號狀態下創建。否則，對此類柵欄的第一次等待將導致超時。我們需要每個[飛行中的幀](#cpu-and-gpu-parallelism)一個柵欄來在GPU和CPU之間同步。用於信號呈現的信號量也是如此。用於信號渲染的信號量數量必須與交換鏈圖像的數量匹配。其原因將在稍後的[命令緩衝區提交](#submit-command-buffer)中解釋。

!!! Tip

	對於更複雜的同步設置，[時間線信號量](https://www.khronos.org/blog/vulkan-timeline-semaphores)可以幫助減少冗長。它們添加了一個帶有計數器值的信號量類型，可以增加和等待，也可以由CPU查詢以替換柵欄。

## 命令緩衝區

與OpenGL等較舊的API不同，你不能在Vulkan中隨意地向GPU發布命令。相反，我們必須將這些記錄到[命令緩衝區](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html)中，然後將它們提交到[佇列](#queues)。

雖然這從應用程式的角度使事情有點複雜，但它有助於驅動程式優化事情，並使應用程式能夠在單獨的線程上記錄命令緩衝區。這是Vulkan允許我們更好地利用CPU和GPU資源的另一個地方。

命令緩衝區必須從[命令池](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandPool.html)分配，這是一個幫助驅動程式優化分配的物件：

```cpp
VkCommandPoolCreateInfo commandPoolCI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
	.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
	.queueFamilyIndex = queueFamily
};
chk(vkCreateCommandPool(device, &commandPoolCI, nullptr, &commandPool));
```

[`VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandPoolCreateFlagBits.html)標誌允許我們在[記錄它們時](#record-command-buffer)隱式重置命令緩衝區。我們還必須指定從此池分配的命令緩衝區將提交到的佇列族。

!!! Tip

	在更複雜的應用程式中，擁有多個命令池並不罕見。它們創建成本低廉，如果你想從多個線程記錄命令緩衝區，每個線程需要一個這樣的池。

命令緩衝區將在CPU上記錄並在GPU上執行，所以我們為最大值創建一個。[飛行中的幀](#cpu-and-gpu-parallelism)：

```cpp
VkCommandBufferAllocateInfo cbAllocCI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
	.commandPool = commandPool,
	.commandBufferCount = maxFramesInFlight
};
chk(vkAllocateCommandBuffers(device, &cbAllocCI, commandBuffers.data()));
```

調用[vkAllocateCommandBuffers](https://docs.vulkan.org/refpages/latest/refpages/source/vkAllocateCommandBuffers.html)將從我們剛創建的池中分配`commandBufferCount`個命令緩衝區。

## 加載紋理

我們現在將加載用於渲染3D模型的紋理。在Vulkan中，這些是圖像，就像交換鏈或深度圖像一樣。從GPU的角度來看，圖像比緩衝區更複雜，這反映在將它們上傳到GPU的冗長性上。

有很多圖像格式，但我們將使用[KTX](https://www.khronos.org/ktx/)，這是Khronos的一種容器格式。與JPEG或PNG等格式不同，它以本機GPU格式存儲圖像，意味著我們可以直接上傳它們而不必解壓縮或轉換。它還支援GPU特定功能，如存儲mip映射、3D紋理和立方體映射。創建KTX圖像檔案的一個工具是[PVRTexTool](https://developer.imaginationtech.com/solutions/pvrtextool/)。

在該庫的幫助下，從磁碟加載這樣的檔案是微不足道的：

```cpp
for (auto i = 0; i < textures.size(); i++) {
	ktxTexture* ktxTexture{ nullptr };
	std::string filename = "assets/suzanne" + std::to_string(i) + ".ktx";
	ktxTexture_CreateFromNamedFile("assets/suzanne.ktx", KTX_TEXTURE_CREATE_LOAD_IMAGE_DATA_BIT, &ktxTexture);
	...
```

!!! Warning

	我們加載的紋理使用每通道8位的RGBA格式，儘管我們不使用alpha通道。你可能會被誘惑使用RGB來節省記憶體，但RGB並不廣泛支援。如果你在OpenGL中使用這樣的格式，驅動程式通常會秘密地將它們轉換為RGBA。在Vulkan中，嘗試使用不支援的格式只會失敗。

創建圖像（物件）非常類似於我們創建[深度附件](#depth-附件)的方式：

```cpp
VkImageCreateInfo texImgCI{
	.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
	.imageType = VK_IMAGE_TYPE_2D,
	.format = ktxTexture_GetVkFormat(ktxTexture),
	.extent = {.width = ktxTexture->baseWidth, .height = ktxTexture->baseHeight, .depth = 1 },
	.mipLevels = ktxTexture->numLevels,
	.arrayLayers = 1,
	.samples = VK_SAMPLE_COUNT_1_BIT,
	.tiling = VK_IMAGE_TILING_OPTIMAL,
	.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT,
	.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
};
VmaAllocationCreateInfo texImageAllocCI{ .usage = VMA_MEMORY_USAGE_AUTO };
chk(vmaCreateImage(allocator, &texImgCI, &texImageAllocCI, &textures[i].image, &textures[i].allocation, nullptr));
```

格式使用`ktxTexture_GetVkFormat`從紋理讀取，寬度、高度和[mip級別](https://docs.vulkan.org/spec/latest/chapters/textures.html#textures-level-of-detail-operation)數量也來自那裡。我們期望的`usage`組合意味著我們希望將從磁碟加載的數據傳輸到此圖像（`VK_IMAGE_USAGE_TRANSFER_DST_BIT`）並且（在稍後的點）希望在著色器中從中採樣（`VK_IMAGE_USAGE_SAMPLED_BIT`）。我們再次使用VK_IMAGE_LAYOUT_UNDEFINED，因為這是在這種情況下唯一允許的（唯一其他允許的格式是VK_IMAGE_LAYOUT_PREINITIALIZED，但它只適用於線性平鋪圖像）。再次使用`vmaCreateImage`創建圖像，`VMA_MEMORY_USAGE_AUTO`確保我們獲得最合適的記憶體類型（GPU VRAM）。

我們還創建一個視圖，通過該視圖將訪問圖像（紋理）。在我們的情況下，我們希望訪問整個圖像，包括所有mip級別：

```cpp
VkImageViewCreateInfo texVewCI{
	.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
	.image = textures[i].image,
	.viewType = VK_IMAGE_VIEW_TYPE_2D,
	.format = texImgCI.format,
	.subresourceRange = {.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .levelCount = ktxTexture->numLevels, .layerCount = 1 }
};
chk(vkCreateImageView(device, &texVewCI, nullptr, &textures[i].view));
```

創建空圖像後，現在是時候上傳數據了。與緩衝區不同，我們不能簡單地將數據memcpy到圖像。這是因為[最佳平鋪](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageTiling.html)以硬體特定的佈局存儲紋素，我們無法轉換到那種佈局。相反，我們必須創建一個中間緩衝區，我們將數據複製到該緩衝區，然後向GPU發布一個命令，將該緩衝區複製到圖像，從而進行轉換。

創建該緩衝區與創建[著色數據緩衝區](#shader-data-buffers)非常相似，有一些小差異：

```cpp
VkBuffer imgSrcBuffer{};
VmaAllocation imgSrcAllocation{};
VkBufferCreateInfo imgSrcBufferCI{
	.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
	.size = (uint32_t)ktxTexture->dataSize,
	.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT
};
VmaAllocationCreateInfo imgSrcAllocCI{
	.flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | VMA_ALLOCATION_CREATE_MAPPED_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
chk(vmaCreateBuffer(allocator, &imgSrcBufferCI, &imgSrcAllocCI, &imgSrcBuffer, &imgSrcAllocation, &imgSrcAllocInfo));
```

此緩衝區將用作緩衝區到圖像複製的臨時源，所以我們需要的唯一標誌是[`VK_BUFFER_USAGE_TRANSFER_SRC_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html)。分配再次由VMA處理。

由於緩衝區是使用可映射標誌創建的，因此將圖像數據放入該緩衝區只是一個簡單的`memcpy`問題：

```cpp
memcpy(imgSrcAllocInfo.pMappedData, ktxTexture->pData, ktxTexture->dataSize);
```

接下來，我們需要將圖像數據從該緩衝區複製到GPU上的最佳平鋪圖像。為此，我們必須創建一個命令緩衝區。我們將在[稍後](#record-command-buffer)詳細介紹它們如何工作。我們還創建一個用於等待命令緩衝區完成執行的柵欄：

```cpp
VkFenceCreateInfo fenceOneTimeCI{
	.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO
};
VkFence fenceOneTime{};
chk(vkCreateFence(device, &fenceOneTimeCI, nullptr, &fenceOneTime));
VkCommandBuffer cbOneTime{};
VkCommandBufferAllocateInfo cbOneTimeAI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
	.commandPool = commandPool,
	.commandBufferCount = 1
};
chk(vkAllocateCommandBuffers(device, &cbOneTimeAI, &cbOneTime));
```

然後我們可以開始記錄將圖像數據獲取到其目標所需的命令：

```cpp
VkCommandBufferBeginInfo cbOneTimeBI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
	.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
};
chk(vkBeginCommandBuffer(cbOneTime, &cbOneTimeBI));
VkImageMemoryBarrier2 barrierTexImage{
	.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
	.srcStageMask = VK_PIPELINE_STAGE_2_NONE,
	.srcAccessMask = VK_ACCESS_2_NONE,
	.dstStageMask = VK_PIPELINE_STAGE_2_TRANSFER_BIT,
	.dstAccessMask = VK_ACCESS_2_TRANSFER_WRITE_BIT,
	.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
	.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
	.image = textures[i].image,
	.subresourceRange = { .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .levelCount = ktxTexture->numLevels, .layerCount = 1 }
};
VkDependencyInfo barrierTexInfo{
	.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
	.imageMemoryBarrierCount = 1,
	.pImageMemoryBarriers = &barrierTexImage
};
vkCmdPipelineBarrier2(cbOneTime, &barrierTexInfo);
std::vector<VkBufferImageCopy> copyRegions{};
for (auto j = 0; j < ktxTexture->numLevels; j++) {
	ktx_size_t mipOffset{0};
	KTX_error_code ret = ktxTexture_GetImageOffset(ktxTexture, j, 0, 0, &mipOffset);
	copyRegions.push_back({
		.bufferOffset = mipOffset,
		.imageSubresource{.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .mipLevel = (uint32_t)j, .layerCount = 1},
		.imageExtent{.width = ktxTexture->baseWidth >> j, .height = ktxTexture->baseHeight >> j, .depth = 1 },
	});
}
vkCmdCopyBufferToImage(cbOneTime, imgSrcBuffer, textures[i].image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, static_cast<uint32_t>(copyRegions.size()), copyRegions.data());
VkImageMemoryBarrier2 barrierTexRead{
	.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
	.srcStageMask = VK_PIPELINE_STAGE_TRANSFER_BIT,
	.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT,
	.dstStageMask = VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
	.dstAccessMask = VK_ACCESS_SHADER_READ_BIT,
	.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
	.newLayout = VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL,
	.image = textures[i].image,
	.subresourceRange = {.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .levelCount = ktxTexture->numLevels, .layerCount = 1 }
};
barrierTexInfo.pImageMemoryBarriers = &barrierTexRead;
vkCmdPipelineBarrier2(cbOneTime, &barrierTexInfo);
chk(vkEndCommandBuffer(cbOneTime));
VkSubmitInfo oneTimeSI{
	.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
	.commandBufferCount = 1,
	.pCommandBuffers = &cbOneTime
};
chk(vkQueueSubmit(queue, 1, &oneTimeSI, fenceOneTime));
chk(vkWaitForFences(device, 1, &fenceOneTime, VK_TRUE, UINT64_MAX));
```

起初看起來有點壓倒性，但很容易解釋。早些時候我們了解了最佳平鋪圖像，其中紋素以硬體特定的佈局存儲，以便GPU最佳訪問。那個[佈局](https://docs.vulkan.org/spec/latest/chapters/resources.html#resources-image-layouts)還定義了可以對圖像執行什麼操作。這就是為什麼我們需要根據我們接下來想對圖像做什麼來更改所述佈局。這是通過[vkCmdPipelineBarrier2](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdPipelineBarrier2.html)發布的管線柵欄完成的。第一個將紋理圖像的所有mip級別從初始未定義佈局轉換為允許我們將數據傳輸到它的佈局（`VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`）。然後我們使用[vkCmdCopyBufferToImage](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdCopyBufferToImage.html)將所有mip級別從我們的臨時緩衝區複製到圖像。最後，我們將mip級別從傳輸目標轉換為我們可以在著色器中讀取的佈局（`VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL`）。將此命令緩衝區提交到圖形佇列然後執行所有這些命令。命令緩衝區提交將在[稍後](#submit-command-buffer)深入解釋。

!!! Tip

	使這更容易的擴展是[VK_EXT_host_image_copy](https://www.khronos.org/blog/copying-images-on-the-host-in-vulkan)，允許直接從CPU複製圖像數據而不必使用命令緩衝區和[VK_KHR_unified_image_layouts](https://www.khronos.org/blog/so-long-image-layouts-simplifying-vulkan-synchronisation)，簡化圖像佈局。這些還沒有廣泛支援，但未來使Vulkan更容易使用的候選者。

稍後我們將在我們的著色器中採樣這些紋理，並且那裡使用的採樣參數由採樣器物件定義。我們希望平滑線性過濾，所以我們啟用[各向異性過濾器](https://docs.vulkan.org/spec/latest/chapters/textures.html#textures-texel-anisotropic-filtering)以減少模糊和混疊。我們還設置最大LOD以使用所有mip級別：

```cpp
VkSamplerCreateInfo samplerCI{
	.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
	.magFilter = VK_FILTER_LINEAR,
	.minFilter = VK_FILTER_LINEAR,
	.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR,
	.anisotropyEnable = VK_TRUE,
	.maxAnisotropy = 8.0f, // 8是廣泛支援的最大各向異性值
	.maxLod = (float)ktxTexture->numLevels,
};
chk(vkCreateSampler(device, &samplerCI, nullptr, &textures[i].sampler));
```

最後，我們清理並存儲該紋理的描述符相關資訊以備將來使用：

```cpp
ktxTexture_Destroy(ktxTexture);
textureDescriptors.push_back({
    .sampler = textures[i].sampler,
    .imageView = textures[i].view,
    .imageLayout = VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL
});
```

現在我們已經上傳了紋理圖像，將它們放入正確的佈局並知道如何採樣它們，我們需要一種方法讓GPU在著色器中訪問它們。從GPU的角度來看，圖像比緩衝區更複雜，因為GPU需要更多關於它們的外觀和訪問方式的資訊。這就是[描述符](https://docs.vulkan.org/spec/latest/chapters/descriptorsets.html)所需的地方，它們是表示（描述，因此得名）著色器資源的句柄。

在較舊的Vulkan版本中，我們也必須將它們用於緩衝區，但如[著色數據緩衝區](#shader-data-buffers)章節所述，緩衝區設備地址使我們免於這樣做。對於圖像，還沒有易於使用或廣泛可用的等效物。

雖然描述符處理仍然是最冗長的部分之一，但使用[描述符索引](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html)大大簡化了這一點，或者使其更容易擴展。有了這個特性，我們可以採用"無綁定"設置，其中所有紋理都放入一個大陣列中，並在[著色器](#the-shader)中索引，而不是必須為每個紋理創建和綁定描述符集。為了演示這如何工作，我們將加載多個紋理。這種方法無論你使用多少紋理（在GPU支援的限制內）都能擴展。

首先，我們以描述符集佈局的形式定義我們的應用程式和著色器之間的介面：

```cpp
VkDescriptorBindingFlags descVariableFlag{ VK_DESCRIPTOR_BINDING_VARIABLE_DESCRIPTOR_COUNT_BIT };
VkDescriptorSetLayoutBindingFlagsCreateInfo descBindingFlags{
	.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
	.bindingCount = 1,
	.pBindingFlags = &descVariableFlag
};
VkDescriptorSetLayoutBinding descLayoutBindingTex{
	.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
	.descriptorCount = static_cast<uint32_t>(textures.size()),
	.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT
};
VkDescriptorSetLayoutCreateInfo descLayoutTexCI{
	.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
	.pNext = &descBindingFlags,
	.bindingCount = 1,
	.pBindings = &descLayoutBindingTex
};
chk(vkCreateDescriptorSetLayout(device, &descLayoutTexCI, nullptr, &descriptorSetLayoutTex));
```

由於我們只對圖像使用描述符，我們只有一個綁定。[VkDescriptorSetLayoutBindingFlagsCreateInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorSetLayoutBindingFlagsCreateInfo.html)用於在該綁定中啟用可變數量的描述符，作為描述符索引的一部分，並通過`pNext`傳遞。我們組合紋理圖像和採樣器（見下文），所以綁定的類型需要是[`VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER`](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorType.html)。該佈局中將有與我們加載的紋理一樣多的描述符，我們只需要從片段著色器訪問它，所以我們將`stageFlags`設置為`VK_SHADER_STAGE_FRAGMENT_BIT`。調用[vkCreateDescriptorSetLayout](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateDescriptorSetLayout.html)然後將創建具有此配置的描述符集佈局。我們需要這個來分配描述符並在[管線創建](#graphics-pipeline)時定義著色器介面。

!!! Tip

	在某些情況下，你可以分離圖像和採樣器，例如，如果你有很多圖像並不想在每個圖像上浪費記憶體來擁有採樣器，或者你想動態使用不同的採樣選項。在這種情況下，你將使用兩個池大小，一個用於`VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE`，一個用於`VK_DESCRIPTOR_TYPE_SAMPLER`。

類似於命令緩衝區，描述符從描述符池分配：

```cpp
VkDescriptorPoolSize poolSize{
	.type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
	.descriptorCount = static_cast<uint32_t>(textures.size())
};
VkDescriptorPoolCreateInfo descPoolCI{
	.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
	.maxSets = 1,
	.poolSizeCount = 1,
	.pPoolSizes = &poolSize
};
chk(vkCreateDescriptorPool(device, &descPoolCI, nullptr, &descriptorPool));
```

我們必須在這裡預先指定要分配的描述符類型數量。我們需要與加載的紋理一樣多的組合圖像和採樣器描述符。我們還必須指定要通過`maxSets`分配多少描述符集（**不是**描述符）。那是一個，因為使用描述符索引，我們使用組合圖像和採樣器的陣列。它也只被GPU訪問，所以不需要每個最大飛行中的幀複製它。正確獲取池大小很重要，因為超出請求數量的分配將失敗。

接下來，我們從該池分配描述符集。雖然描述符集佈局定義了介面，但描述符包含實際的描述符數據。佈局和集分開的原因是因為你可以混合佈局並將它們重新用於不同的描述符集。

```cpp
uint32_t variableDescCount{ static_cast<uint32_t>(textures.size()) };
VkDescriptorSetVariableDescriptorCountAllocateInfo variableDescCountAI{
	.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO_EXT,
	.descriptorSetCount = 1,
	.pDescriptorCounts = &variableDescCount
};
VkDescriptorSetAllocateInfo texDescSetAlloc{
	.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
	.pNext = &variableDescCountAI,
	.descriptorPool = descriptorPool,
	.descriptorSetCount = 1,
	.pSetLayouts = &descriptorSetLayoutTex
};
chk(vkAllocateDescriptorSets(device, &texDescSetAlloc, &descriptorSetTex));
```

類似於描述符集佈局創建，我們必須通過`pNext`中的[VkDescriptorSetVariableDescriptorCountAllocateInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorSetVariableDescriptorCountAllocateInfo.html)將描述符索引設置傳遞給分配。

由[vkAllocateDescriptorSets](https://docs.vulkan.org/refpages/latest/refpages/source/vkAllocateDescriptorSets.html)分配的描述符集基本上未初始化，需要在著色器中訪問它之前用實際數據支持：

```cpp
VkWriteDescriptorSet writeDescSet{
	.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
	.dstSet = descriptorSetTex,
	.dstBinding = 0,
	.descriptorCount = static_cast<uint32_t>(textureDescriptors.size()),
	.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
	.pImageInfo = textureDescriptors.data()
};
vkUpdateDescriptorSets(device, 1, &writeDescSet, 0, nullptr);
```

[VkDescriptorImageInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorImageInfo.html)指的是我們上面加載的紋理的描述符陣列，在`pImageInfo`中與採樣器組合。調用[vkUpdateDescriptorSets](https://docs.vulkan.org/refpages/latest/refpages/source/vkUpdateDescriptorSets.html)將把該資訊放入描述符集的第一個（在我們的情況下是唯一的）綁定槽中。

## 加載著色器

如前所述，我們將使用[Slang語言](https://github.com/shader-slang)編寫在GPU上運行的著色器。Vulkan不能直接加載用這樣的語言（或GLSL或HLSL）編寫的著色器。它期望它們採用SPIR-V中間格式。為此，我們需要首先從Slang編譯到SPIR-V。有兩種方法可以做到這一點：使用Slang的命令列編譯器離線編譯或使用Slang的庫在運行時編譯。

我們將採用後者，因為這使更新著色器更容易。使用離線編譯，你必須在每次更改著色器時重新編譯它們，或者找到一種方法讓構建系統為你做這件事。使用運行時編譯，我們在運行代碼時將始終使用最新的著色器版本。

要編譯Slang著色器，我們首先創建一個全局Slang會話，這是我們的應用程式和Slang庫之間的連接：

```cpp
slang::createGlobalSession(slangGlobalSession.writeRef());
```

接下來，我們創建一個會話來定義我們的編譯範圍。我們想編譯到SPIR-V，所以我們將目標`format`設置為`SLANG_SPIRV`。我們使用[SPIR-V 1.4](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_spirv_1_4.html)作為著色器特性的基準。自Vulkan 1.2以來，這已成為核心，所以在這種情況下保證得到支援。我們還將`defaultMatrixLayoutMode`更改為列主佈局以匹配我們稍後用於構建矩陣的GLM庫的佈局：

```cpp
auto slangTargets{ std::to_array<slang::TargetDesc>({ {
	.format{SLANG_SPIRV},
	.profile{slangGlobalSession->findProfile("spirv_1_4")}
} })};
auto slangOptions{ std::to_array<slang::CompilerOptionEntry>({ {
	slang::CompilerOptionName::EmitSpirvDirectly,
	{slang::CompilerOptionValueKind::Int, 1}
} })};
slang::SessionDesc slangSessionDesc{
	.targets{slangTargets.data()},
	.targetCount{SlangInt(slangTargets.size())},
	.defaultMatrixLayoutMode = SLANG_MATRIX_LAYOUT_COLUMN_MAJOR,
	.compilerOptionEntries{slangOptions.data()},
	.compilerOptionEntryCount{uint32_t(slangOptions.size())}
};
Slang::ComPtr<slang::ISession> slangSession;
slangGlobalSession->createSession(slangSessionDesc, slangSession.writeRef());
```

`createSession`創建的會話然後可用於獲取Slang著色器的SPIR-V表示。為此，我們首先使用`loadModuleFromSource`從檔案加載文本著色器，然後使用`getTargetCode`將我們著色器中的所有入口點編譯為SPIR-V：

```cpp
Slang::ComPtr<slang::IModule> slangModule{
    slangSession->loadModuleFromSource("triangle", "assets/shader.slang", nullptr, nullptr)
};
Slang::ComPtr<ISlangBlob> spirv;
slangModule->getTargetCode(0, spirv.writeRef());
```

要在我們的圖形管線中使用我們的著色器（見下文），我們需要創建一個著色器模組。這些是編譯後的SPIR-V著色器的容器。要創建這樣的模組，我們將Slang編譯的SPIR-V傳遞給[`vkCreateShaderModule`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateShaderModule.html)：

```cpp
VkShaderModuleCreateInfo shaderModuleCI{
	.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
	.codeSize = spirv->getBufferSize(),
	.pCode = (uint32_t*)spirv->getBufferPointer()
};
VkShaderModule shaderModule{};
chk(vkCreateShaderModule(device, &shaderModuleCI, nullptr, &shaderModule));
```

!!! Tip

	[VK_KHR_maintenance5](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_maintenance5.html)擴展，它在Vulkan 1.4中成為核心，棄用了著色器模組。它允許直接將`VkShaderModuleCreateInfo`傳遞到管線的著色器階段創建資訊。

## 著色器

雖然著色語言不如CPU編程語言強大，但它們仍然可以處理複雜的場景。我們的著色器故意保持簡單：

```hlsl
struct VSInput {
    float3 Pos;
    float3 Normal;
	float2 UV;
};

Sampler2D textures[];

struct ShaderData {
    float4x4 projection;
    float4x4 view;
    float4x4 model[3];
    float4 lightPos;
    uint32_t selected;
};

struct VSOutput {
    float4 Pos : SV_POSITION;
    float3 Normal;
    float2 UV;
    float3 Factor;
    float3 LightVec;
    float3 ViewVec;
    uint32_t InstanceIndex;
};

[shader("vertex")]
VSOutput main(VSInput input, uniform ShaderData *shaderData, uint instanceIndex : SV_VulkanInstanceID) {
    VSOutput output;
    float4x4 modelMat = shaderData->model[instanceIndex];
    output.Normal = mul((float3x3)mul(shaderData->view, modelMat), input.Normal);
    output.UV = input.UV;
    output.Pos = mul(shaderData->projection, mul(shaderData->view, mul(modelMat, float4(input.Pos.xyz, 1.0))));
    output.Factor = (shaderData->selected == instanceIndex ? 3.0f : 1.0f);
    output.InstanceIndex = instanceIndex;
    // 計算光照所需的視圖向量
    float4 fragPos = mul(mul(shaderData->view, modelMat), float4(input.Pos.xyz, 1.0));
    output.LightVec = shaderData->lightPos.xyz - fragPos.xyz;
    output.ViewVec = -fragPos.xyz;
    return output;
}

[shader("fragment")]
float4 main(VSOutput input) {
    // Phong光照
    float3 N = normalize(input.Normal);
    float3 L = normalize(input.LightVec);
    float3 V = normalize(input.ViewVec);
    float3 R = reflect(-L, N);
    float3 diffuse = max(dot(N, L), 0.0025);
    float3 specular = pow(max(dot(R, V), 0.0), 16.0) * 0.75;
    // 從紋理採樣
    float3 color = textures[NonUniformResourceIndex(input.InstanceIndex)].Sample(input.UV).rgb * input.Factor;
    return float4(diffuse * color.rgb + specular, 1.0);
}
```

!!! Tip

	Slang允許我們將所有著色器階段放入一個檔案中。這消除了複製著色器介面或將其放入共享包含的需要。它還使著色器更容易閱讀（和編輯）。

它包含兩個著色階段，從定義不同階段使用的結構開始。`ShaderData`結構與[CPU端](#shader-data-buffers)定義的著色數據結構的佈局匹配。

首先是頂點著色器，由`[shader("vertex")]`屬性標記。它接受按`VSInput`定義的頂點，匹配[圖形管線](#graphics-pipeline)的頂點佈局。頂點著色器將為每個頂點[繪製](#record-command-buffer)調用。由於我們使用緩衝區設備地址，我們將UBO作為指針傳遞和訪問。由於我們繪製3D模型的多個實例並希望為每個實例使用不同的矩陣，我們使用內置的`SV_VulkanInstanceID`系統值來索引到模型矩陣。我們還希望突出顯示所選模型，所以如果當前實例與該選擇匹配，我們將不同的顏色因數傳遞給片段著色器。

其次是片段著色器，由`[shader("fragment")]`屬性標記。首先，我們使用從頂點著色器傳遞的值計算一些基本光照，使用[phong反射模型](https://en.wikipedia.org/wiki/Phong_reflection_model)。然後，為了演示描述符索引，我們使用實例索引從紋理陣列（`Sampler2D textures[]`）讀取，最後將其與光照計算組合。這被寫入當前顏色附件。

## 圖形管線

Vulkan與OpenGL有很大不同的另一個領域是狀態管理。OpenGL是一個巨大的狀態機器，該狀態可以隨時更改。這使得驅動程式很難優化事情。Vulkan通過引入管線狀態物件從根本上改變了這一點。它們在"編譯"的管線物件中提供了一整套管線狀態，給驅動程式優化它們的機會。這些物件還允許在例如單獨的線程中創建管線物件。如果你需要不同的管線狀態，你必須創建一個新的管線狀態物件。

!!! Note

	Vulkan中有*一些*狀態可以是動態的。主要是視口和剪刀設置等基本狀態。它們是動態的對驅動程式來說不是問題。有幾個擴展使額外的狀態動態化，但我們在這裡不使用它們。

Vulkan支援特定於用例的[管線類型](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineBindPoint.html)，如圖形、計算、光線追蹤。因此，設置管線取決於我們想要實現什麼。在我們的情況下，這是圖形（也稱為[光柵化](https://en.wikipedia.org/wiki/Rasterisation)），所以我們將創建一個圖形管線。

首先，我們創建一個管線佈局。這定義了管線和我們的著色器之間的介面。管線佈局是單獨的物件，因為你可以混合和匹配它們以與其他管線一起使用：

```cpp
VkPushConstantRange pushConstantRange{
	.stageFlags = VK_SHADER_STAGE_VERTEX_BIT,
	.size = sizeof(VkDeviceAddress)
};
VkPipelineLayoutCreateInfo pipelineLayoutCI{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
	.setLayoutCount = 1,
	.pSetLayouts = &descriptorSetLayoutTex,
	.pushConstantRangeCount = 1,
	.pPushConstantRanges = &pushConstantRange
};
chk(vkCreatePipelineLayout(device, &pipelineLayoutCI, nullptr, &pipelineLayout));
```

[`pushConstantRange`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPushConstantRange.html)定義了一個值範圍，我們可以直接推送到著色器而不必通過緩衝區。我們使用這些來傳遞指向著色數據緩衝區緩衝區的指針（稍後會詳細介紹）。描述符集佈局（`pSetLayouts`）定義了到著色器資源的介面。在我們的情況下，這只是一個用於傳遞紋理圖像描述符的佈局。調用[`vkCreatePipelineLayout`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineLayoutCreateInfo.html)將創建我們可以然後用於我們管線的管線佈局。

我們管線和著色器之間介面的另一個部分是頂點數據的佈局。在[網格加載章節](#loading-meshes)中，我們定義了一個基本頂點結構，現在我們需要用Vulkan術語指定它。我們使用單個頂點緩衝區，所以我們需要一個[頂點綁定點](https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputBindingDescription.html)。`stride`與我們頂點結構的大小匹配，因為我們的頂點直接相鄰存儲在記憶體中。`inputRate`是每個頂點，意味著數據指針為每個讀取的頂點前進：

```cpp
VkVertexInputBindingDescription vertexBinding{
	 .binding = 0,
	 .stride = sizeof(Vertex),
	 .inputRate = VK_VERTEX_INPUT_RATE_VERTEX
};
```

接下來，我們指定位置、法線和紋理坐標的[頂點屬性](https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputAttributeDescription.html)如何在記憶體中佈局。這與我們的CPU端頂點結構完全匹配：

```cpp
std::vector<VkVertexInputAttributeDescription> vertexAttributes{
	{ .location = 0, .binding = 0, .format = VK_FORMAT_R32G32B32_SFLOAT },
	{ .location = 1, .binding = 0, .format = VK_FORMAT_R32G32B32_SFLOAT, .offset = offsetof(Vertex, normal) },
	{ .location = 2, .binding = 0, .format = VK_FORMAT_R32G32_SFLOAT, .offset = offsetof(Vertex, uv) },
};
```
!!! Tip

	在著色器中訪問頂點的另一個選項是緩衝區設備地址。這樣，我們將跳過傳統的頂點屬性，並在著色器中使用指針手動獲取它們。這被稱為"頂點拉取"。但在某些設備上這可能會更慢，所以我們堅持使用傳統方式。

現在我們開始填充創建管線所需的許多`VkPipeline*CreateInfo`結構。我們不會詳細解釋所有這些，你可以在[規範](https://docs.vulkan.org/refpages/latest/refpages/source/VkGraphicsPipelineCreateInfo.html)中閱讀它們。它們都有點相似，並描述管線的特定部分。

首先是[頂點輸入](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineVertexInputStateCreateInfo.html)的管線狀態，我們在上面定義了：

```cpp
VkPipelineVertexInputStateCreateInfo vertexInputState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
	.vertexBindingDescriptionCount = 1,
	.pVertexBindingDescriptions = &vertexBinding,
	.vertexAttributeDescriptionCount = static_cast<uint32_t>(vertexAttributes.size()),
	.pVertexAttributeDescriptions = vertexAttributes.data(),
};
```

另一個直接連接到我們頂點數據的結構是[輸入組裝狀態](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineInputAssemblyStateCreateInfo.html)。它定義了[圖元](https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html)如何組裝。我們想渲染一個獨立三角形的列表，所以我們使用[`VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html)：

```cpp
VkPipelineInputAssemblyStateCreateInfo inputAssemblyState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
	.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
};
```

任何管線的重要部分是我們想使用的[著色器](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineShaderStageCreateInfo.html)以及它們映射到的管線階段。只有一組著色器是我們只需要一個管線的原因。感謝Slang，我們在一個著色器模組中獲得所有階段：

```cpp
std::vector<VkPipelineShaderStageCreateInfo> shaderStages{
	{ .sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
      .stage = VK_SHADER_STAGE_VERTEX_BIT,
      .module = shaderModule, .pName = "main"},
	{ .sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
      .stage = VK_SHADER_STAGE_FRAGMENT_BIT,
      .module = shaderModule, .pName = "main" }
};
```

!!! Tip

	如果你想使用不同的著色器（或著色器組合），你必須創建多個管線。[VK_EXT_shader_objects](https://www.khronos.org/blog/you-can-use-vulkan-without-pipelines-today)將這些著色器階段變成單獨的物件，並為API的這一部分增加了更多靈活性。

接下來，我們配置[視口狀態](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineViewportStateCreateInfo.html)。我們使用一個視口和一個剪刀，我們還希望它們是動態狀態，這樣我們不必在這些中的任何一個更改時重新創建管線，例如在調整視窗大小時。這是自Vulkan 1.0以來存在的少數動態狀態之一：

```cpp
VkPipelineViewportStateCreateInfo viewportState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
	.viewportCount = 1,
	.scissorCount = 1
};
std::vector<VkDynamicState> dynamicStates{ VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR };
VkPipelineDynamicStateCreateInfo dynamicState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
	.dynamicStateCount = 2,
	.pDynamicStates = dynamicStates.data()
};
```

由於我們想使用[深度緩衝](#depth-attachment)，我們配置[深度/模板狀態](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineDepthStencilStateCreateInfo.html)以啟用深度測試和寫入，並設置比較操作，使更接近觀察者的片段通過深度測試：

```cpp
VkPipelineDepthStencilStateCreateInfo depthStencilState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
	.depthTestEnable = VK_TRUE,
	.depthWriteEnable = VK_TRUE,
	.depthCompareOp = VK_COMPARE_OP_LESS_OR_EQUAL
};
```

以下狀態告訴管線我們想使用動態渲染而不是繁瑣的渲染通道物件。與渲染通道不同，設置這個非常簡單，並且還移除了管線和渲染通道之間的緊密耦合。對於動態渲染，我們只需要指定我們計劃使用（稍後）的附件的數量和格式：

```cpp
VkPipelineRenderingCreateInfo renderingCI{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO,
	.colorAttachmentCount = 1,
	.pColorAttachmentFormats = &imageFormat,
	.depthAttachmentFormat = depthFormat
};
```

!!! Note

	由於此功能是在Vulkan生命週期的後期添加的，因此在管線創建資訊中沒有專用的成員。我們將其傳遞給`pNext`（見下文）

我們不使用以下狀態，但必須指定它們，並且需要有一些合理的默認值。所以我們將[混合](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineColorBlendStateCreateInfo.html)、[光柵化](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineRasterizationStateCreateInfo.html)和[多重採樣](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineMultisampleStateCreateInfo.html)設置為默認值：

```cpp
VkPipelineColorBlendAttachmentState blendAttachment{
	.colorWriteMask = 0xF
};
VkPipelineColorBlendStateCreateInfo colorBlendState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
	.attachmentCount = 1,
	.pAttachments = &blendAttachment
};
VkPipelineRasterizationStateCreateInfo rasterizationState{
	 .sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
	 .lineWidth = 1.0f
};
VkPipelineMultisampleStateCreateInfo multisampleState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
	.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT
};
```

有了所有相關的管線狀態創建結構正確設置，我們將它們連接起來最終創建我們的圖形管線：

```cpp
VkGraphicsPipelineCreateInfo pipelineCI{
	.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
	.pNext = &renderingCI,
	.stageCount = 2,
	.pStages = shaderStages.data(),
	.pVertexInputState = &vertexInputState,
	.pInputAssemblyState = &inputAssemblyState,
	.pViewportState = &viewportState,
	.pRasterizationState = &rasterizationState,
	.pMultisampleState = &multisampleState,
	.pDepthStencilState = &depthStencilState,
	.pColorBlendState = &colorBlendState,
	.pDynamicState = &dynamicState,
	.layout = pipelineLayout
};
chk(vkCreateGraphicsPipelines(device, VK_NULL_HANDLE, 1, &pipelineCI, nullptr, &pipeline));
```

成功調用[`vkCreateGraphicsPipelines`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateGraphicsPipelines.html)後，我們的圖形管線準備好用於渲染。

## 渲染循環

到達這一點花了相當多的努力，但我們現在準備好實際向螢幕"繪製"某些東西。像以前一樣，這在Vulkan中既是顯式的又是間接的。如今，將某些東西顯示在螢幕上是一個複雜的事情，與早期計算機圖形的工作方式相比。特別是對於一個必須支援如此多不同平台和設備的API。

這使我們進入渲染循環，在其中我們將處理用戶輸入、渲染我們的場景、更新著色器值，並確保所有這些在CPU和GPU之間以及在GPU本身上正確同步：

```cpp
uint64_t lastTime{ SDL_GetTicks() };
bool quit{ false };
while (!quit) {
	// 等待柵欄
	// 獲取下一個圖像
	// 更新著色數據
	// 記錄命令緩衝區
	// 提交命令緩衝區
	// 呈現圖像
	// 輪詢事件
}
```

只要視窗保持打開，循環就會執行。SDL還為我們提供了精確的[計時函數](https://wiki.libsdl.org/SDL3/SDL_GetTicks)，我們用於測量經過的時間以進行與幀率無關的計算。

循環內部發生了很多事情，所以我們現在將分別查看每個部分。

### 等待柵欄

如[CPU和GPU並行](#cpu-and-gpu-parallelism)中所述，我們可以重疊CPU和GPU工作的一個領域是命令緩衝區記錄。我們希望CPU開始記錄下一個命令緩衝區，而GPU仍在處理上一個命令緩衝區。

為此，我們等待GPU處理的最後一幀的柵欄完成執行：

```cpp
chk(vkWaitForFences(device, 1, &fences[frameIndex], true, UINT64_MAX));
chk(vkResetFences(device, 1, &fences[frameIndex]));
```

調用[vkWaitForFences](https://docs.vulkan.org/refpages/latest/refpages/source/vkWaitForFences.html)將在CPU上等待，直到GPU信號表示它已完成使用該柵欄提交的所有工作。我們使用一個故意大的超時值`UINT64_MAX`。由於柵欄仍處於信號狀態，我們還需要[重置](https://docs.vulkan.org/refpages/latest/refpages/source/vkResetFences.html)它以進行下一次提交。

!!! Note

	我們對圖形操作允許多長時間沒有要求，所以我們實際上不關心超時。我們不執行任何特別複雜的任務，柵欄通常會在幾毫秒內信號。此外，大多數操作系統實現了在圖形任務花費太長時間時重置GPU的功能。

### 獲取下一個圖像

由於我們不直接控制[交換鏈圖像](#swapchain)，我們需要"請求"（獲取）交換鏈以獲取要在這一幀中使用的下一個索引：

```cpp
chkSwapchain(vkAcquireNextImageKHR(device, swapchain, UINT64_MAX, presentSemaphores[frameIndex], VK_NULL_HANDLE, &imageIndex));
```

重要的是使用[vkAcquireNextImageKHR](https://docs.vulkan.org/refpages/latest/refpages/source/vkAcquireNextImageKHR.html)返回的圖像索引來訪問交換鏈圖像。這是因為不保證圖像按連續順序獲取。這就是我們有兩個索引的原因之一。

我們還將一個[信號量](#synchronization-objects)傳遞給此函數，該信號量將在命令緩衝區提交時使用。

!!! Note

	我們使用`chk`函數的變體來檢查與呈現相關的調用的返回值。這是由於[VK_ERROR_OUT_OF_DATE_KHR](https://docs.vulkan.org/spec/latest/chapters/fundamentals.html#VkResult)，當表面不再與交換鏈兼容時返回。這可能發生在某些平台上，例如，如果顯示方向更改。為了防止應用程式在這些情況下退出，我們在`chkSwapchain`中顯式處理此錯誤。我們不退出，而是為下一幀重新創建交換鏈。

### 更新著色數據

我們希望下一幀使用最新的用戶輸入。在等待柵欄後，現在可以安全地執行此操作。為此，我們使用glm從當前數據更新矩陣：

```cpp
shaderData.projection = glm::perspective(glm::radians(45.0f), (float)window.getSize().x / (float)window.getSize().y, 0.1f, 32.0f);
shaderData.view = glm::translate(glm::mat4(1.0f), camPos);
for (auto i = 0; i < 3; i++) {
	auto instancePos = glm::vec3((float)(i - 1) * 3.0f, 0.0f, 0.0f);
	shaderData.model[i] = glm::translate(glm::mat4(1.0f), instancePos) * glm::mat4_cast(glm::quat(objectRotations[i]));
}
```

一個簡單的`memcpy`到著色數據緩衝區的持久映射指針足以使這對GPU可用（並對我們的著色器而言）：

```cpp
memcpy(shaderDataBuffers[frameIndex].allocationInfo.pMappedData, &shaderData, sizeof(ShaderData));
```

這之所以有效，是因為[著色數據緩衝區](#shader-data-buffers)存儲在可被CPU（用於寫入）和GPU（用於讀取）訪問的記憶體類型中。通過前面的柵欄同步，我們還確保CPU不會在GPU完成讀取之前開始寫入該著色數據緩衝區。

### 記錄命令緩衝區

現在我們終於可以開始記錄實際的GPU工作項了。我們需要許多東西之前已經討論過，所以即使這將是很多代碼，它應該很容易跟隨。如[命令緩衝區](#command-buffers)中所述，命令不是直接發布到GPU的，而是記錄到命令緩衝區中。這正是我們要做的：記錄單個渲染幀的命令。

你可能會被誘惑預先記錄命令緩衝區並重用它們，直到發生需要重新記錄的更改。然而，這使事情不必要地複雜，因為你必須實現與CPU/GPU並行工作的更新邏輯。並且由於記錄命令緩衝區相對較快，如果需要可以卸載到其他CPU線程，每幀記錄它們是完全沒問題的。

!!! Note

	記錄到命令緩衝區中的命令以`vkCmd`開頭。它們不直接執行，只有在命令緩衝區提交到佇列（GPU時間線）時才執行。這也解釋了為什麼這些命令不返回結果。初學者的一個常見錯誤是將這些命令與在CPU時間線上立即執行的命令混合。重要的是要記住這兩個不同的時間線存在。

命令緩衝區有一個我們必須遵守的[生命週期](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html#commandbuffers-lifecycle)。例如，我們不能在它處於可執行狀態時記錄命令到它。這也由[驗證層](#validation-layers)檢查，如果我們誤用東西，它會讓我們知道。

首先，我們需要將命令緩衝區移動到初始狀態。這是通過[重置它](https://docs.vulkan.org/refpages/latest/refpages/source/vkResetCommandBuffer.html)完成的，現在可以安全地這樣做，因為我們早些時候等待了柵欄以確保它不再處於掛起狀態：

```cpp
auto cb = commandBuffers[frameIndex];
chk(vkResetCommandBuffer(cb, 0));
```

重置後，我們可以開始記錄命令緩衝區：

```cpp
VkCommandBufferBeginInfo cbBI {
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
	.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
};
chk(vkBeginCommandBuffer(cb, &cbBI));
```

[`VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandBufferUsageFlagBits.html)標誌影響生命週期在執行後如何移動到無效狀態，並可以由驅動程式用作優化提示。調用[vkBeginCommandBuffer](https://docs.vulkan.org/refpages/latest/refpages/source/vkBeginCommandBuffer.html)後，它將命令緩衝區移動到記錄狀態，我們可以開始記錄實際命令。

在渲染期間，顏色資訊將寫入當前[交換鏈圖像](#swapchain)，深度資訊將寫入[深度圖像](#depth-attachment)。如我們在[加載紋理](#loading-textures)中所學，最佳平鋪圖像需要處於正確的佈局以用於其預期用例。因此，第一步是為兩者發布佈局轉換：

```cpp
std::array<VkImageMemoryBarrier2, 2> outputBarriers{
	VkImageMemoryBarrier2{
		.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
		.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
		.srcAccessMask = 0,
		.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
		.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
		.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
		.newLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
		.image = swapchainImages[imageIndex],
		.subresourceRange{.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .levelCount = 1, .layerCount = 1 }
	},
	VkImageMemoryBarrier2{
		.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
		.srcStageMask = VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT | VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT,
		.srcAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
		.dstStageMask = VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT | VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT,
		.dstAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
		.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
		.newLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
		.image = depthImage,
		.subresourceRange{.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT, .levelCount = 1, .layerCount = 1 }
	}
		};
VkDependencyInfo barrierDependencyInfo{
	.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
	.imageMemoryBarrierCount = 2,
	.pImageMemoryBarriers = outputBarriers.data()
};
vkCmdPipelineBarrier2(cb, &barrierDependencyInfo);
```

不僅[圖像記憶體柵欄](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-dependencies)轉換佈局，它們還確保這在正確的[管線階段](https://docs.vulkan.org/spec/latest/chapters/pipelines.html#pipelines-block-diagram)發生，在命令緩衝區內強制排序。類似於我們使用的其他同步原語，這些是必要的，以確保GPU例如不在前一個管線階段仍在從中讀取時在一個管線階段開始寫入圖像。它們還使寫入對後續階段可見。`srcStageMask`是要等待的管線階段，`srcAccessMask`定義要使其可用的寫入。`dstStageMask`和`dstAccessMask`定義在何處以及使哪些寫入可見。

!!! Note

	可用和可見聽起來可能像同一回事，但它們不是。這是由於CPU/GPU如何工作以及它們如何與快取交互。可用意味著數據準備好用於將來的記憶體操作（例如快取刷新）。可見意味著數據實際上對來自消費階段的讀取可見。

*第一個柵欄*將當前交換鏈圖像*轉換*到[佈局](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html)（`newLayout`），以便我們可以將其用作渲染的顏色附件。類似地，*第二個柵欄*將深度圖像*轉換*到佈局，以便我們可以將其用作渲染的深度附件。兩者都*從*未定義佈局（`oldLayout`）*轉換*。這是因為我們不需要這些圖像中的任何先前內容。

!!! Tip

	`VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL`佈局是Vulkan 1.3的核心特性，它將所有類型的附件佈局組合到一個佈局中。這簡化了圖像柵欄。

調用[vkCmdPipelineBarrier2](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdPipelineBarrier2.html)然後將這兩個柵欄插入當前命令緩衝區。

有了處於正確佈局的附件，現在是時候定義我們將如何使用它們。如早些時候所述，我們將使用[動態渲染](https://www.khronos.org/blog/streamlining-render-passes)來做這件事，而不是Vulkan 1.0中複雜和繁瑣的渲染通道物件。

```cpp
VkRenderingAttachmentInfo colorAttachmentInfo{
	.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
	.imageView = swapchainImageViews[imageIndex],
	.imageLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
	.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
	.storeOp = VK_ATTACHMENT_STORE_OP_STORE,
	.clearValue{.color{ 0.0f, 0.0f, 0.2f, 1.0f }}
};
VkRenderingAttachmentInfo depthAttachmentInfo{
	.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
	.imageView = depthImageView,
	.imageLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
	.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
	.storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE,
	.clearValue = {.depthStencil = {1.0f,  0}}
};
```

我們為用作顏色附件的交換鏈圖像和用作深度附件的深度圖像設置一個[VkRenderingAttachmentInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkRenderingAttachmentInfo.html)。兩者都將在渲染通道開始時清除為各自的`clearValue`，`loadOp`設置為`VK_ATTACHMENT_LOAD_OP_CLEAR`。顏色附件的`storeOp`配置為保留其內容，因為我們仍然需要將它們呈現到螢幕。一旦我們完成渲染，我們不需要深度資訊，所以我們實際上不關心渲染通道後其內容發生了什麼。兩者的佈局必須與我們早些時候轉換它們的佈局匹配。

調用[vkCmdBeginRendering](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdBeginRendering.html)然後將使用上述附件配置開始我們的動態渲染通道實例：

```cpp
VkRenderingInfo renderingInfo{
	.sType = VK_STRUCTURE_TYPE_RENDERING_INFO,
	.renderArea{.extent{.width = window.getSize().x, .height = window.getSize().y }},
	.layerCount = 1,
	.colorAttachmentCount = 1,
	.pColorAttachments = &colorAttachmentInfo,
	.pDepthAttachment = &depthAttachmentInfo
};
vkCmdBeginRendering(cb, &renderingInfo);
```

在此渲染通道實例內，我們終於可以開始記錄GPU命令。記住，這些還沒有發布到GPU，只是記錄到當前命令緩衝區中。

我們首先設置[視口](https://docs.vulkan.org/spec/latest/chapters/vertexpostproc.html#vertexpostproc-viewport)來定義我們的渲染區域。我們總是希望這是整個視窗。[剪刀](https://docs.vulkan.org/spec/latest/chapters/fragops.html#fragops-scissor)區域也是如此。兩者都是我們在[管線創建](#graphics-pipeline)時啟用的動態狀態的一部分，所以我們可以在命令緩衝區內調整它們，而不必在每次視窗調整大小時重新創建圖形管線：

```cpp
VkViewport vp{
    .width = static_cast<float>(window.getSize().x),
    .height = static_cast<float>(window.getSize().y),
    .minDepth = 0.0f,
    .maxDepth = 1.0f
};
vkCmdSetViewport(cb, 0, 1, &vp);
VkRect2D scissor{ .extent{ .width = window.getSize().x, .height = window.getSize().y } };
vkCmdSetScissor(cb, 0, 1, &scissor);
```

接下來是綁定參與渲染我們3D物件的資源。[圖形管線](#graphics-pipeline)，也包括我們的頂點和片段著色器，以及我們[紋理圖像](#loading-textures)陣列的描述符集和我們[3D網格](#loading-meshes)的頂點和索引緩衝區：

```cpp
vkCmdBindPipeline(cb, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);
VkDeviceSize vOffset{ 0 };
vkCmdBindDescriptorSets(cb, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &descriptorSetTex, 0, nullptr);
vkCmdBindVertexBuffers(cb, 0, 1, &vBuffer, &vOffset);
vkCmdBindIndexBuffer(cb, vBuffer, vBufSize, VK_INDEX_TYPE_UINT16);
```

我們還希望訪問[著色數據緩衝區](#shader-data-buffer)中的數據。我們選擇使用緩衝區設備地址而不是通過描述符，所以我們通過推送常量將當前幀的著色數據緩衝區的地址傳遞給著色器：

```cpp
vkCmdPushConstants(cb, pipelineLayout, VK_SHADER_STAGE_VERTEX_BIT, 0, sizeof(VkDeviceAddress), &shaderDataBuffers[frameIndex].deviceAddress);
```

!!! Note

	這些`vkCmd*`調用（以及許多其他調用）設置當前命令緩衝區狀態。這意味著它們在此命令緩衝區內的多個繪製調用中持續存在。因此，如果你例如想發布具有相同管線但不同描述符集的第二個繪製調用，你只需要用另一個集調用`vkCmdBindDescriptorSets`，同時保持狀態的其餘部分。

有了這些，我們*終於*準備好發布一個實際的繪製命令。有了我們到目前為止所做的所有工作，這只是一個命令：

```cpp
vkCmdDrawIndexed(cb, indexCount, 3, 0, 0, 0);
```

調用[vkCmdDrawIndexed](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdDrawIndexed.html)將從當前綁定的索引和頂點緩衝區繪製indexCount / 3個三角形。我們還想繪製我們3D網格的多個實例，所以我們將實例計數（第三個參數）設置為3，我們在[頂點著色器](#the-shader)中使用它來索引到[模型矩陣](#shader-data-buffers)。

我們現在[完成](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdEndRendering.html)當前渲染通道：

```cpp
vkCmdEndRendering(cb);
```

並將我們剛用作附件（以輸出顏色值）的交換鏈圖像轉換為[呈現](#present-image)所需的佈局：

```cpp
VkImageMemoryBarrier2 barrierPresent{
	.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
	.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
	.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
	.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
	.dstAccessMask = 0,
	.oldLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
	.newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
	.image = swapchainImages[imageIndex],
	.subresourceRange{.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .levelCount = 1, .layerCount = 1 }
};
VkDependencyInfo barrierPresentDependencyInfo{
	.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
	.imageMemoryBarrierCount = 1,
	.pImageMemoryBarriers = &barrierPresent
};
vkCmdPipelineBarrier2(cb, &barrierPresentDependencyInfo);
```

我們不需要深度附件的柵欄，因為我們不在此渲染通道之外使用它。

最後，我們[結束記錄](https://docs.vulkan.org/refpages/latest/refpages/source/vkEndCommandBuffer.html)命令緩衝區：

```cpp
vkEndCommandBuffer(cb);
```

這將其移動到[可執行狀態](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html#commandbuffers-lifecycle)。這是下一步的要求。

### 提交命令緩衝區

為了執行我們剛記錄的命令，我們需要將命令緩衝區提交到匹配的佇列。在實際應用程式中，擁有多個不同類型的佇列和更複雜的提交模式並不罕見。但我們只使用圖形命令（沒有計算或光線追蹤），因此也只有一個圖形佇列，我們將當前幀的命令緩衝區提交到它：

```cpp
VkPipelineStageFlags waitStages = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
VkSubmitInfo submitInfo{
	.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
	.waitSemaphoreCount = 1,
	.pWaitSemaphores = &presentSemaphores[frameIndex],
	.pWaitDstStageMask = &waitStages,
	.commandBufferCount = 1,
	.pCommandBuffers = &cb,
	.signalSemaphoreCount = 1,
	.pSignalSemaphores = &renderSemaphores[imageIndex],
};
chk(vkQueueSubmit(queue, 1, &submitInfo, fences[frameIndex]));
```

[`VkSubmitInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkSubmitInfo.html)結構需要一些解釋，特別是關於同步。早些時候我們了解了[同步原語](#synchronization-objects)，我們需要正確同步CPU和GPU之間以及GPU本身的工作。這就是所有這些結合在一起的地方。

`pWaitSemaphores`中的信號量確保提交的命令緩衝區在當前幀的呈現完成之前不開始執行。`pWaitDstStageMask`中的管線階段將使該等待發生在管線的顏色附件輸出階段，因此（理論上）GPU可能已經開始對在此階段之前的管線部分進行工作，例如獲取頂點。另一方面，`pSignalSemaphores`中的信號信號量是GPU在命令緩衝區執行完成後信號的信號量。這種組合確保不會發生讀/寫危險，使GPU讀取或寫入仍在使用的資源。

注意對呈現信號量使用`frameIndex`和對渲染信號量使用`imageIndex`的區別。這是因為`vkQueuePresentKHR`（見下文）沒有沒有某個擴展（尚未在任何地方可用）的信號方法。為了解決這個問題，我們解耦了兩種信號量類型，並為每個交換鏈圖像使用一個呈現信號量。可以在[Vulkan指南](https://docs.vulkan.org/guide/latest/swapchain_semaphore_reuse.html)中找到深入解釋。

!!! Warning

	提交可以有多個等待和信號信號量以及等待階段。在比我們更複雜的應用程式中（可能將圖形與計算混合），重要的是保持同步範圍盡可能窄，以允許GPU重疊工作。這是Vulkan中最難正確處理的部分之一。可以使用[驗證層](#validation-layers)檢測錯誤，可以使用供應商特定的圖形分析器檢查效能。

一旦工作已提交，我們可以計算下一個渲染循環迭代的幀索引：

```cpp
frameIndex = (frameIndex + 1) % maxFramesInFlight;
```

### 呈現圖像

使我們的渲染結果到螢幕的最後一步是呈現我們用作顏色附件的當前交換鏈圖像：

```cpp
VkPresentInfoKHR presentInfo{
	.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
	.waitSemaphoreCount = 1,
	.pWaitSemaphores = &renderSemaphores[imageIndex],
	.swapchainCount = 1,
	.pSwapchains = &swapchain,
	.pImageIndices = &imageIndex
};
chkSwapchain(vkQueuePresentKHR(queue, &presentInfo));
```

調用[vkQueuePresentKHR](https://docs.vulkan.org/refpages/latest/refpages/source/vkQueuePresentKHR.html)將在等待渲染信號量後將圖像排隊進行呈現。這保證圖像不會在我們的渲染命令完成之前呈現。

### 輪詢事件

最後但同樣重要的是，我們處理操作系統的事件佇列。感謝SDL，此代碼是平台無關的。事件處理是在一個額外的循環中完成的（在渲染循環內），我們調用SDL的[事件輪詢函數](https://wiki.libsdl.org/SDL3/SDL_PollEvent)直到所有事件都被處理。我們只處理我們感興趣的事件類型：

```cpp
float elapsedTime{ (SDL_GetTicks() - lastTime) / 1000.0f };
lastTime = SDL_GetTicks();
for (SDL_Event event; SDL_PollEvent(&event);) {

	// 如果應用程式即將關閉，則退出循環
	if (event.type == SDL_EVENT_QUIT) {
		quit = true;
		break;
	}

	// 使用滑鼠拖動旋轉所選物件
	if (event.type == SDL_EVENT_MOUSE_MOTION) {
		if (event.button.button == SDL_BUTTON_LEFT) {
			objectRotations[shaderData.selected].x -= (float)event.motion.yrel * elapsedTime;
			objectRotations[shaderData.selected].y += (float)event.motion.xrel * elapsedTime;
		}
	}

	// 使用滑鼠滾輪縮放
	if (event.type == SDL_EVENT_MOUSE_WHEEL) {
		camPos.z += (float)event.wheel.y * elapsedTime * 10.0f;
	}

	// 選擇活動模型實例
	if (event.type == SDL_EVENT_KEY_DOWN) {
		if (event.key.key == SDLK_PLUS || event.key.key == SDLK_KP_PLUS) {
			shaderData.selected = (shaderData.selected < 2) ? shaderData.selected + 1 : 0;
		}
		if (event.key.key == SDLK_MINUS || event.key.key == SDLK_KP_MINUS) {
			shaderData.selected = (shaderData.selected > 0) ? shaderData.selected - 1 : 2;
		}
	}

	// 視窗調整大小
	if (event.type == SDL_EVENT_WINDOW_RESIZED) {
		updateSwapchain = true;
	}
}
```

我們希望在我們的應用程式中有一些交互性。為此，我們在`SDL_EVENT_MOUSE_MOTION`事件中根據按下左鍕時的滑鼠移動計算當前選定模型實例的旋轉。`SDL_EVENT_MOUSE_WHEEL`中的滑鼠滾輪也是如此，以允許縮放相機進出。`SDL_EVENT_KEY_DOWN`事件讓我們使用加號和減號鍵在模型實例之間切換。

當我們的應用程式要關閉時，無論如何，都會調用`SDL_EVENT_QUIT`事件。在這種情況下，我們將`quit`設置為true，退出外部渲染循環並跳轉到代碼的[清理](#cleaning-up)部分。

雖然是可選的，並且遊戲經常不實現，但我們也通過`SDL_EVENT_WINDOW_RESIZED`事件處理調整大小，這需要重新創建交換鏈和相關資源。

### 重新創建交換鏈

當視窗調整大小或其表面變為[過時](#acquire-next-image)時，需要重新創建交換鏈。如果這些操作中的任何一個請求更新交換鏈，我們重新創建它：

```cpp
if (updateSwapchain) {
	updateSwapchain = false;
	vkDeviceWaitIdle(device);
	chk(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(devices[deviceIndex], surface, &surfaceCaps));
	swapchainCI.oldSwapchain = swapchain;
	swapchainCI.imageExtent = { .width = static_cast<uint32_t>(resized->size.x), .height = static_cast<uint32_t>(resized->size.y) };
	chk(vkCreateSwapchainKHR(device, &swapchainCI, nullptr, &swapchain));
	for (auto i = 0; i < imageCount; i++) {
		vkDestroyImageView(device, swapchainImageViews[i], nullptr);
	}
	chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, nullptr));
	swapchainImages.resize(imageCount);
	chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, swapchainImages.data()));
	swapchainImageViews.resize(imageCount);
	for (auto i = 0; i < imageCount; i++) {
		VkImageViewCreateInfo viewCI{
			.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
			.image = swapchainImages[i],
			.viewType = VK_IMAGE_VIEW_TYPE_2D,
			.format = imageFormat,
			.subresourceRange = {.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .levelCount = 1, .layerCount = 1}
		};
		chk(vkCreateImageView(device, &viewCI, nullptr, &swapchainImageViews[i]));
	}
	vkDestroySwapchainKHR(device, swapchainCI.oldSwapchain, nullptr);
	vmaDestroyImage(allocator, depthImage, depthImageAllocation);
	vkDestroyImageView(device, depthImageView, nullptr);
	depthImageCI.extent = { .width = static_cast<uint32_t>(window.getSize().x), .height = static_cast<uint32_t>(window.getSize().y), .depth = 1 };
	VmaAllocationCreateInfo allocCI{
		.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT,
		.usage = VMA_MEMORY_USAGE_AUTO
	};
	chk(vmaCreateImage(allocator, &depthImageCI, &allocCI, &depthImage, &depthImageAllocation, nullptr));
	VkImageViewCreateInfo viewCI{
		.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
		.image = depthImage,
		.viewType = VK_IMAGE_VIEW_TYPE_2D,
		.format = depthFormat,
		.subresourceRange = {.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT, .levelCount = 1, .layerCount = 1 }
	};
	chk(vkCreateImageView(device, &viewCI, nullptr, &depthImageView));
}
```

起初這看起來令人生畏，但它主要是我們早些時候用於創建交換鏈和深度圖像的代碼。在我們可以重新創建這些之前，我們調用[vkDeviceWaitIdle](https://docs.vulkan.org/refpages/latest/refpages/source/vkDeviceWaitIdle.html)等待GPU完成所有未完成的操作。這確保這些物件中沒有一個仍在被GPU使用。

一個重要的區別是設置交換鏈創建資訊的`oldSwapchain`成員。這在重新創建期間是必要的，以允許應用程式繼續呈現任何已獲取的圖像。記住我們不控制這些，因為它們由交換鏈（和操作系統）擁有。除此之外，這是一個簡單的問題，銷毀現有物件（`vkDestroy*`）並像我們早些時候那樣創建它們的新物件，只是使用視窗的新大小。

## 清理

銷毀Vulkan資源與創建它們一樣顯式。理論上，你可以退出應用程式而不這樣做，並讓操作系統為你清理。但正確地為你清理是常識，所以我們這樣做。我們再次調用vkDeviceWaitIdle以確保我們要銷毀的GPU資源中沒有一個仍在使用。一旦該調用成功完成，我們可以開始清理我們在應用程式中創建的所有Vulkan GPU物件：

```cpp
chk(vkDeviceWaitIdle(device));
for (auto i = 0; i < maxFramesInFlight; i++) {
	vkDestroyFence(device, fences[i], nullptr);
	vkDestroySemaphore(device, presentSemaphores[i], nullptr);
	...
}
vmaDestroyImage(allocator, depthImage, depthImageAllocation);
...
vkDestroyCommandPool(device, commandPool, nullptr);
vmaDestroyAllocator(allocator);
vkDestroyDevice(device, nullptr);
vkDestroyInstance(instance, nullptr);
```

命令的排序只對VMA分配器、設備和實例重要。這些應該只在從它們創建的所有物件之後銷毀。實例應該最後刪除，這樣我們將被驗證層（當啟用時）通知我們忘記正確刪除的每個物件。你不必顯式銷毀的一個資源是命令緩衝區。調用[vkDestroyCommandPool](https://docs.vulkan.org/refpages/latest/refpages/source/vkDestroyCommandPool.html)將隱式釋放從該池分配的所有命令緩衝區。

## 結束語

到目前為止，你應該對如何創建執行光柵化並利用最近API版本和特性的Vulkan應用程式有了基本了解。Vulkan仍然是一個相對冗長的API，這是其顯式、低級設計固有的。雖然我們仍然需要大量代碼來在Vulkan中運行某些東西，但它更容易理解並更靈活，使其成為更複雜應用程式的堅實基礎。

從更廣泛的角度來看，2026年的Vulkan支援比以往更廣泛的用例。除了光柵化和計算，它還提供硬體加速光線追蹤、視訊編碼和解碼、機器學習和安全關鍵領域的功能。

如果你正在尋找更多資源，請查看[Vulkan文檔站點](https://docs.vulkan.org/)。它將多個Vulkan文檔資源（如規範、教程和示例）組合到一個方便的單一網站中。
