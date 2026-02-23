<!--
Copyright (c) 2025-2026, Sascha Willems
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# 2026年的Vulkan入门指南

!!! Info

	最后更新时间：2026-02-21：通过VMA实现持久缓冲区映射


## 简介

[本仓库](https://github.com/SaschaWillems/HowToVulkan)和配套教程演示了在2026年编写[Vulkan](https://vulkan.org/)图形应用程序的方法。目标是利用现代特性简化Vulkan的使用，并在此过程中创建一些超出基本彩色三角形的内容。

Vulkan发布已近10年，发生了很大变化。1.0版本不得不做出许多妥协，以支持桌面和移动平台上广泛的GPU。一些初始概念如渲染通道(渲染通道)后来发现并不那么优化，已被替代方案取代。API日趋成熟，新增了光线追踪、视频加速和机器学习等新领域。与API同样重要的是生态系统，它也发生了很大变化，为我们提供了使用GLSL之外的语言编写着色器的新选项，以及帮助使用Vulkan的工具。

因此，本教程将以[Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html)为基础。这使我们可以访问几个使Vulkan更易于使用的特性，同时仍支持广泛的GPU和平台。我们将使用的特性包括：

* [动态渲染](https://www.khronos.org/blog/streamlining-render-passes) - 大大简化渲染通道设置，这是Vulkan最受批评的领域之一
* [缓冲区设备地址](https://docs.vulkan.org/guide/latest/buffer_device_address.html) - 让我们可以通过指针访问缓冲区，而不是通过描述符
* [描述符索引](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html) - 简化描述符管理，通常被称为"无绑定"(bindless)
* [同步2](https://docs.vulkan.org/guide/latest/extensions/VK_KHR_synchronization2.html) - 改进同步处理，这是Vulkan最困难的领域之一

简而言之：在2026年使用Vulkan与在2016年使用Vulkan可能非常不同。这正是我希望通过本教程展示的内容。

!!! Tip

	支持至少Vulkan 1.3的设备列表可以在[这里](https://vulkan.gpuinfo.org/listdevices.php?apiversion=1.3)找到。


## 目标受众

本教程专注于编写实际的Vulkan代码，并尽可能快地让程序运行起来（可能在一个下午内完成）。它不会解释编程、软件架构、图形概念或Vulkan的工作原理（详细）。相反，它经常包含相关信息的链接，如[Vulkan规范](https://docs.vulkan.org/)。你应该至少具备C/C++和实时图形概念的基本知识。

## 目标

我们专注于光栅化，Vulkan的其他部分如计算或光线追踪不在本教程范围内。在本教程结束时，我们将在屏幕上显示多个有光照和纹理的3D对象，可以使用鼠标旋转它们（[截图](images/screenshot.png)）。源代码在一个文件中，只有几百行代码，没有抽象层，没有难以理解的现代C++语言特性或面向对象的把戏。我相信能够从上到下跟随源代码，而不必经过多层抽象，会使它更容易理解。

## 许可证

版权所有 (c) 2025-2026, [Sascha Willems](https://www.saschawillems.de)。本文档内容根据[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)许可证授权。源代码列表和文件根据MIT许可证授权。

## 库

Vulkan是一个显式的低级API。为它编写代码可能非常冗长。为了专注于有趣的部分，我们将使用以下库：

* [SDL](https://www.libsdl.org/) - 窗口和输入（以及本教程中未使用的其他功能）。没有这样的库，我们将不得不编写大量平台特定的代码。替代方案包括[GLFW](https://www.glfw.org/)和[SFML](https://www.sfml-dev.org/)。在这些库中，SDL具有最广泛的平台支持
* [Volk](https://github.com/zeux/volk) - 元加载器，简化Vulkan函数的加载
* [VMA](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator) - 简化内存分配的处理。减少了内存管理周围的一些冗长代码
* [glm](https://github.com/g-truc/glm) - 支持矩阵和向量等功能的数学库
* [tinyobjloader](https://github.com/tinyobjloader/tinyobjloader) - obj 3D格式的单头文件加载器
* [KTX-Software](https://github.com/KhronosGroup/KTX-Software) - Khronos KTX GPU纹理图像文件加载器

!!! Tip

	这些库都不是使用Vulkan所必需的。但它们使使用Vulkan变得更容易，其中一些如VMA和Volk被广泛使用，即使在商业应用程序中也是如此。

## 编程语言

我们将使用C++ 20，主要是因为它的指定初始化器。它们有助于减轻Vulkan的冗长性并提高代码可读性。除此之外，我们不会使用现代C++特性，并且使用C Vulkan头文件而不是[C++](https://github.com/KhronosGroup/Vulkan-Hpp)头文件。除了个人偏好之外，这样做是为了使本教程尽可能易于理解，包括使用其他编程语言的人。

## 着色语言

Vulkan使用一种称为[SPIR-V](https://www.khronos.org/spirv/)的中间格式来处理着色器。这将API与实际的着色语言解耦。最初只支持GLSL，但在2026年有更多更好的选择。其中之一是[Slang](https://github.com/shader-slang)，这也是我们将在本教程中使用的。该语言本身比GLSL更现代，并提供了一些便利的功能。

## Vulkan SDK

虽然开发Vulkan应用程序不是必需的，但[LunarG Vulkan SDK](https://vulkan.lunarg.com/sdk/home)提供了一种方便的方式来安装常用库和工具，其中一些在本教程中使用。因此建议安装它。安装时，确保选择可选的GLM、Volk、SDL3和Vulkan Memory Allocator组件。或者，你可以从各自的仓库下载这些库，并调整CMakeLists.txt文件中的包含路径。

## 验证层

Vulkan的设计旨在最小化驱动程序开销。虽然这*可以*导致更好的性能，但它也移除了像OpenGL这样的API所具有的许多保护措施，并将这一责任交给你。如果你错误使用Vulkan，驱动程序可能会崩溃。因此，即使你的应用程序在一个GPU上工作，也不能保证它在其他GPU上也能工作。另一方面，Vulkan规范定义了所有功能的有效用法。并且存在[验证层](https://github.com/KhronosGroup/Vulkan-ValidationLayers)，这是一个易于使用的工具，可以检查这些用法。

验证层可以在代码中启用，但更简单的方法是通过[Vulkan SDK](#vulkan-sdk)提供的[Vulkan配置器GUI](https://vulkan.lunarg.com/doc/view/latest/windows/vkconfig.html)启用这些层。一旦启用，任何对API的不当使用都将记录到我们应用程序的命令行窗口中。

!!! Note

	在使用Vulkan进行开发时，应该始终启用验证层。这确保你编写符合规范的代码，该代码可以在其他系统上正常工作。

## 图形调试器

另一个不可或缺的工具是图形调试器。类似于Visual Studio等IDE中可用的CPU调试器，这些工具帮助你调试GPU端的运行时问题。一个常用的跨平台和跨供应商的Vulkan支持图形调试器是[RenderDoc](https://renderdoc.org/)。虽然在本教程中不需要使用这样的调试器，但如果你想在所学的基础上继续学习并在此过程中遇到问题，它将非常有价值。

## 开发环境

我们的构建系统将是[CMake](https://cmake.org/)。类似于我编写代码的方法，事情将尽可能保持简单，同时具有能够使用各种C++编译器和IDE遵循本教程的额外好处。

要为你的C++ IDE创建构建文件，请在项目的源文件夹中运行CMake，如下所示：

```bash
cmake -B build -G "Visual Studio 17 2022"
```

这将在`build`文件夹中写入Visual Studio 2022解决方案文件。作为命令行的替代方案，你可以使用[cmake-gui](https://cmake.org/cmake/help/latest/manual/cmake-gui.1.html)。生成器(-G)取决于你的IDE，你可以在[这里](https://cmake.org/cmake/help/latest/manual/cmake-generators.7.html)找到这些生成器的列表。

## 源代码

现在一切都已经正确设置，我们可以开始深入研究代码了。以下章节将从上到下引导你了解[主源文件](https://github.com/SaschaWillems/HowToVulkan/blob/main/source/main.cpp)。

!!! Warning

	本文档中省略了一些不太有趣的初始化、声明和样板代码。建议在进行本教程时同时打开主源文件。

## 实例设置

我们需要的第一件事是Vulkan实例。它将应用程序连接到Vulkan，因此是后续一切的基础。

设置实例包括传递关于你的应用程序的信息：

```cpp
VkApplicationInfo appInfo{
	.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
	.pApplicationName = "How to Vulkan",
	.apiVersion = VK_API_VERSION_1_3
};
```

最重要的是`apiVersion`，它告诉Vulkan我们要使用Vulkan 1.3。使用更高的API版本可以让我们开箱即用地获得更多功能，否则必须通过扩展来使用这些功能。[Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html)得到广泛支持，并添加了许多使Vulkan更易于使用的核心功能。`pApplicationName`可用于标识你的应用程序。

!!! Info

	你会经常看到的一个结构成员是`sType`。驱动程序需要知道它要处理什么类型的结构，而由于Vulkan是一个C-API，除了通过结构成员指定之外没有其他方法。

实例还需要知道你想使用的扩展。顾名思义，这些用于扩展API。由于实例创建（以及其他一些事情）是平台特定的，实例需要知道你想使用哪些平台特定的扩展。例如，对于Windows，你会使用[VK_KHR_win32_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_win32_surface.html)，对于Android则使用[VK_KHR_android_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_android_surface.html)，其他平台也是如此。

!!! Note

	Vulkan中有两种扩展类型。实例扩展和设备扩展。前者主要是全局的，通常是与GPU无关的平台特定扩展，后者基于你的GPU的能力。

这意味着我们不得不编写平台特定的代码。**但是**，使用像SDL这样的库，我们不必这样做，而是向SDL请求平台特定的实例扩展：

```cpp
uint32_t instanceExtensionsCount{ 0 };
char const* const* instanceExtensions{ SDL_Vulkan_GetInstanceExtensions(&instanceExtensionsCount) };
```

所以不再需要担心平台特定的事情。有了应用程序信息和所需的扩展设置，我们可以创建我们的实例：

```cpp
VkInstanceCreateInfo instanceCI{
	.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
	.pApplicationInfo = &appInfo,
	.enabledExtensionCount = instanceExtensionsCount,
	.ppEnabledExtensionNames = instanceExtensions,
};
chk(vkCreateInstance(&instanceCI, nullptr, &instance));
```

这非常简单。我们传递我们的应用程序信息以及SDL给我们的实例扩展的名称和数量（针对我们编译的平台）。调用[`vkCreateInstance`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateInstance.html)创建我们的实例。

!!! Tip

	大多数Vulkan函数可能以不同方式失败，并返回[`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html)值。我们使用一个名为`chk`的小内联函数来检查该返回代码，如果出错则退出应用程序。在实际应用程序中，你应该进行更复杂的错误处理。

## 设备选择

现在我们需要选择要用于渲染的设备。虽然这不常见，但在单个系统中可能有多个支持Vulkan的设备。例如，如果你安装了多个GPU，或者你有集成显卡和独立显卡：

!!! Info

	在处理Vulkan时，一个常用的术语是实现。这指的是实现Vulkan API的东西。通常是你的GPU的驱动程序，但也可能是基于CPU的软件实现。为了保持简单，我们将在本教程的其余部分使用术语GPU。

为此，我们获取所有支持Vulkan的可用物理设备的列表：

```cpp
uint32_t deviceCount{ 0 };
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr));
std::vector<VkPhysicalDevice> devices(deviceCount);
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data()));
```

在第二次调用[`vkEnumeratePhysicalDevices`](https://docs.vulkan.org/refpages/latest/refpages/source/vkEnumeratePhysicalDevices.html)之后，我们有了一个包含所有可用支持Vulkan的设备的列表。

!!! Info

	必须调用两次返回某种列表的函数在Vulkan C-API中很常见。第一次调用将返回元素数量，然后用于正确调整结果列表的大小。第二次调用然后填充实际的结果列表。

由于大多数系统只有一个设备，我们只是实现一种简单且可选的方法，通过将所需的设备索引作为命令行参数传递来选择设备：

```cpp
uint32_t deviceIndex{ 0 };
if (argc > 1) {
	deviceIndex = std::stoi(argv[1]);
	assert(deviceIndex < deviceCount);
}
```

我们还希望显示所选设备的信息。为此，我们调用[`vkGetPhysicalDeviceProperties2`](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceProperties2.html)并将设备名称输出到控制台：

```cpp
VkPhysicalDeviceProperties2 deviceProperties{ .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2 };
vkGetPhysicalDeviceProperties2(devices[deviceIndex], &deviceProperties);
std::cout << "Selected device: " << deviceProperties.properties.deviceName <<  "
";
```

!!! Info

	你可能已经注意到`VkPhysicalDeviceProperties2`和`vkGetPhysicalDeviceProperties2`的后缀是`2`。这样做是为了[解决](https://docs.vulkan.org/spec/latest/appendices/legacy.html)以前版本的缺点。修复原始函数和结构不是一个选项，因为那会破坏API兼容性。

## 队列

在Vulkan中，工作不是直接提交到设备，而是提交到队列。队列抽象了对硬件（图形、计算、传输、视频等）的访问。它们组织在队列族中，每个族描述一组具有共同功能的队列。可用的队列类型在GPU之间有所不同。由于我们只进行图形操作，我们只需要找到一个支持图形的队列族。这是通过检查[`VK_QUEUE_GRAPHICS_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkQueueFlagBits.html)标志来完成的：

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

由于我们要使用该图形队列[呈现](#present-image)某些内容到屏幕，我们还检查该队列是否支持呈现：

```cpp
chk(SDL_Vulkan_GetPresentationSupport(instance, devices[deviceIndex], queueFamily));
```

!!! Tip

	没有支持图形的队列族的设备在现实中非常罕见。此外，在大多数设备上，第一个队列族支持图形、计算和呈现。像我们上面那样检查这仍然是一个好习惯，特别是当你想使用其他队列类型如计算时。如果你遇到图形、计算和/或呈现需要不同队列族的设备，你必须在这些队列之间进行额外的同步。

对于我们的下一步，我们需要使用[`VkDeviceQueueCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkDeviceQueueCreateInfo.html)来引用该队列族。可以从同一族请求多个队列，但我们不需要那样做。这就是为什么我们需要在`pQueuePriorities`中指定优先级（在我们的情况下只有一个）。对于来自同一族的多个队列，驱动程序可能会使用该信息来优先处理工作：

```cpp
const float qfpriorities{ 1.0f };
VkDeviceQueueCreateInfo queueCI{
	.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
	.queueFamilyIndex = queueFamily,
	.queueCount = 1,
	.pQueuePriorities = &qfpriorities
};
```

## 设备设置

现在我们有了到Vulkan库的连接，选择了一个物理设备，并且知道我们要使用哪个队列族，我们需要获取GPU的句柄。这在Vulkan中称为**设备**。Vulkan区分物理设备和逻辑设备。前者表示实际的设备（通常是GPU），后者表示对该设备的Vulkan实现的句柄，应用程序将与之交互。

设备创建的一个重要部分是请求我们要使用的特性和扩展。我们的实例是使用Vulkan 1.3作为基础创建的，这几乎给了我们想要使用的所有特性。所以我们只需要请求[`VK_KHR_swapchain`](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_swapchain.html)扩展，以便能够向屏幕呈现某些内容：

```cpp
const std::vector<const char*> deviceExtensions{ VK_KHR_SWAPCHAIN_EXTENSION_NAME };
```

!!! Tip

	Vulkan头文件为所有扩展定义了常量，如`VK_KHR_SWAPCHAIN_EXTENSION_NAME`。你可以使用这些常量而不是将它们的名称写为字符串。这有助于避免扩展名称中的拼写错误。

使用Vulkan 1.3作为基础，我们可以使用[前面](#about)提到的特性，而不必求助于扩展。使用扩展时，需要更多的代码，并且如果扩展不存在，需要检查和回退路径。对于核心特性，我们可以简单地启用它们：

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

`shaderSampledImageArrayNonUniformIndexing`、`descriptorBindingVariableDescriptorCount`和`runtimeDescriptorArray`与描述符索引相关，其余名称与实际特性匹配。我们还启用了[各向异性过滤](https://docs.vulkan.org/refpages/latest/refpages/source/VkPhysicalDeviceFeatures.html#_members)以获得更好的纹理过滤。

!!! Info

	你将经常看到的另一个Vulkan结构成员是`pNext`。这可以用于创建一个传递给函数调用的结构链表。驱动程序然后使用该列表中每个结构的`sType`成员来识别所述结构的类型。

有了所有东西，我们可以创建一个逻辑设备，其中包含我们要使用的核心特性、扩展和队列族：

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

我们还需要一个队列来提交我们的图形命令，现在可以从我们刚创建的设备中请求它：

```cpp
vkGetDeviceQueue(device, queueFamily, 0, &queue);
```

## 设置VMA

Vulkan是一个显式API，这也适用于内存管理。如库列表中所述，我们将使用[Vulkan内存分配器(VMA)](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator)来大大简化这一领域。

VMA提供了一个用于分配内存的分配器。这需要为你的项目设置一次。为此，我们传入一些常用Vulkan函数的指针、我们的Vulkan实例和设备，我们还启用对缓冲区设备地址的支持(`flags`)：

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

	VMA也使用[`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html)返回代码，我们可以使用相同的`chk`函数来检查VMA的函数结果。

## 窗口和表面

要在Vulkan中"绘制"某些内容（正确的术语应该是"呈现图像"，稍后会详细介绍），我们需要一个表面。大多数情况下，表面是从窗口获取的。创建两者都是平台特定的，如[实例章节](#instance-setup)中所述。因此，理论上，这*将*需要我们为所有想要支持的平台（Windows、Linux、Android等）编写不同的代码路径。

但这就是像SDL这样的库发挥作用的地方。它们为我们处理所有平台特定的细节，所以那部分变得非常简单。

!!! Tip

	像SDL、GLFW和SFML这样的库也处理其他平台特定的功能，如输入、音频和网络（程度不同）。

首先，我们创建一个支持Vulkan的窗口：

```cpp
SDL_Window* window = SDL_CreateWindow("How to Vulkan", 1280u, 720u, SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE);
```

然后为该窗口请求一个Vulkan表面：

```cpp
chk(SDL_Vulkan_CreateSurface(window, instance, nullptr, &surface));
```

对于以下章节，我们需要知道我们刚刚创建的表面的属性，所以我们通过[`vkGetPhysicalDeviceSurfaceCapabilitiesKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceSurfaceCapabilitiesKHR.html)获取它们并存储以供将来参考：

```cpp
VkSurfaceCapabilitiesKHR surfaceCaps{};
chk(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(devices[deviceIndex], surface, &surfaceCaps));
```

## 交换链

为了在视觉上向表面（在我们的情况下是窗口）呈现某些内容，我们需要创建一个交换链。它基本上是一系列图像，存储颜色信息，你将这些图像排队到操作系统的呈现引擎中。[`VkSwapchainCreateInfoKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkSwapchainCreateInfoKHR.html)非常广泛，需要一些解释。

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

我们使用4分量颜色格式`VK_FORMAT_B8G8R8A8_SRGB`和非线性sRGB[颜色空间](https://docs.vulkan.org/refpages/latest/refpages/source/VkColorSpaceKHR.html)`VK_COLORSPACE_SRGB_NONLINEAR_KHR`。这种组合保证在任何地方都可用。不同的组合需要检查支持。`minImageCount`将是我们从交换链获得的最小图像数。这个值在GPU之间变化，因此我们使用之前从表面请求的信息。`presentMode`定义了图像呈现到屏幕的方式。[`VK_PRESENT_MODE_FIFO_KHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPresentModeKHR.html#)是一个v-sync模式，是保证在任何地方都唯一可用的模式。

!!! Note

	这里显示的交换链设置是一个最低限度。在实际应用程序中，这部分可能相当复杂，因为你可能需要根据用户设置进行调整。一个例子是支持HDR的设备，你需要使用不同的图像格式和颜色空间。

交换链的一个特殊之处是它的图像不属于应用程序，而是属于交换链。因此，我们不是显式创建这些图像，而是从交换链请求它们。这将给我们至少与`minImageCount`设置的图像一样多的图像：

```cpp
uint32_t imageCount{ 0 };
chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, nullptr));
swapchainImages.resize(imageCount);
chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, swapchainImages.data()));
swapchainImageViews.resize(imageCount);
```

## 深度附件

由于我们渲染三维对象，我们希望确保它们正确显示，无论你从什么角度查看它们，或者它们的三角形以什么顺序进行光栅化。这是通过[深度测试](https://docs.vulkan.org/spec/latest/chapters/fragops.html#fragops-depth)完成的，要使用它，我们需要一个深度附件。

首先，我们需要使用[vkGetPhysicalDeviceFormatProperties2](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceFormatProperties2.html)检查当前GPU上实际可用的深度格式：

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

	Vulkan规范[保证]((https://docs.vulkan.org/spec/latest/chapters/formats.html#features-required-format-support))某些格式和用法组合在所有设备上都受支持。其中一个保证是对于深度格式，必须支持`VK_FORMAT_D32_SFLOAT_S8_UINT`或`VK_FORMAT_D24_UNORM_S8_UINT`之一作为深度附件。

深度图像的属性然后在[`VkImageCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageCreateInfo.html)结构中定义。其中一些与交换链创建中的属性类似：

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
图像是2D的，使用支持深度的格式。我们不需要多个mip级别或层。使用[`VK_IMAGE_TILING_OPTIMAL`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageTiling.html)的最佳平铺确保图像以最适合GPU的格式存储。我们还需要声明我们对该图像的预期用例，即[`VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageUsageFlagBits.html)，因为我们将把它用作渲染输出的深度附件（稍后会详细介绍）。初始布局定义图像的内容，我们不需要关心，所以我们将其设置为[`VK_IMAGE_LAYOUT_UNDEFINED`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html)。

这也是我们第一次使用VMA在Vulkan中分配某些东西。Vulkan中缓冲区和图像的内存分配非常冗长，但通常非常相似。使用VMA，我们可以避免很多这种情况。VMA还处理选择正确的内存类型和使用标志，否则需要大量代码才能正确处理。

```cpp
VmaAllocationCreateInfo allocCI{
	.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
chk(vmaCreateImage(allocator, &depthImageCI, &allocCI, &depthImage, &depthImageAllocation, nullptr));
```

使VMA如此方便的一件事是[`VMA_MEMORY_USAGE_AUTO`](https://gpuopen-librariesandsdks.github.io/VulkanMemoryAllocator/html/choosing_memory_type.html)。这个使用标志将让VMA根据你为分配和/或缓冲区创建信息传递的其他值自动选择所需的使用标志。在某些情况下，你最好显式声明使用标志，但在大多数情况下，自动标志是完美的选择。`VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT`标志告诉VMA为此资源创建单独的内存分配，这对于例如大型图像附件是推荐的。

!!! Tip

	我们只需要一个图像，即使我们在其他地方进行双缓冲。这是因为图像只能由GPU访问，而GPU一次只能写入一个深度图像。这与CPU和GPU共享的资源不同，但稍后会详细介绍。

Vulkan中的图像不是直接访问的，而是通过[视图](https://docs.vulkan.org/spec/latest/chapters/resources.html#VkImageView)访问，这是编程中的一个常见概念。这增加了灵活性，并允许对同一图像进行不同的访问模式。

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

我们需要一个我们刚刚创建的图像的视图，并且我们希望将其作为2D视图访问。`subresourceRange`指定我们要通过此视图访问的图像部分。对于具有多个层或(mip)级别的图像，你可以为其中任何一个创建单独的图像视图，并以不同方式访问图像。`aspectMask`指的是我们要通过视图访问的图像的方面。这可以是颜色、模板或（在我们的情况下）图像的深度部分。

有了图像和图像视图都创建好了，我们的深度附件现在准备好稍后用于渲染。

## 加载网格

从Vulkan的角度来看，绘制单个三角形和具有数千个三角形的复杂网格之间没有技术区别。两者都会导致GPU从中读取数据的某种缓冲区。GPU不关心数据来自哪里。我们可以从显示带有硬编码顶点数据的单个三角形开始，但为了学习体验，加载实际的3D对象要好得多。这就是我们的下一步。

有很多格式可以存储3D模型。[glTF](https://www.khronos.org/Gltf)例如提供了许多功能，并且以类似于Vulkan的方式可扩展。但我们要保持简单，所以我们将使用[Wavefront .obj格式](https://en.wikipedia.org/wiki/Wavefront_.obj_file)代替。就3D格式而言，它不会比这更简单了。而且它被许多工具支持，如[Blender](https://www.blender.org/)。

首先，我们声明一个结构体，用于我们计划在应用程序中使用的顶点数据。那是顶点位置、顶点法线（用于光照）和纹理坐标。这些通常缩写为[uv](https://en.wikipedia.org/wiki/UV_mapping)：

```cpp
struct Vertex {
	glm::vec3 pos;
	glm::vec3 normal;
	glm::vec2 uv;
};
```

我们使用[tinyobjloader库](https://github.com/tinyobjloader/tinyobjloader)来加载.obj文件。它完成所有解析，并让我们可以结构化地访问该文件中包含的数据：

```cpp
// 网格数据
tinyobj::attrib_t attrib;
std::vector<tinyobj::shape_t> shapes;
std::vector<tinyobj::material_t> materials;
chk(tinyobj::LoadObj(&attrib, &shapes, &materials, nullptr, nullptr, "assets/suzanne.obj"));
```

成功调用`LoadObj`后，我们可以访问存储在所选.obj文件中的顶点数据。`attrib`包含顶点数据的线性数组，`shapes`包含对该数据的索引。`materials`不会被使用，我们将进行自己的着色。

!!! Warning

	.obj格式有点过时，并不在所有方面与现代3D管道匹配。其中一方面是顶点数据的索引。由于.obj文件的结构方式，我们最终每个顶点有一个索引，这限制了索引渲染的有效性。在实际应用程序中，你会使用与索引渲染配合良好的格式，如glTF。

我们将使用交错顶点属性。交错意味着，在内存中，对于每个顶点，位置的三个浮点数后面跟着法线向量的三个浮点数（用于光照），然后是纹理坐标的两个浮点数。

为了使这工作，我们需要转换tinyobj提供的位置、法线和纹理坐标值数据：

```cpp
const VkDeviceSize indexCount{shapes[0].mesh.indices.size()};
std::vector<Vertex> vertices{};
std::vector<uint16_t> indices{};
// 加载顶点和索引数据
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

	位置和法线的y轴值以及纹理坐标的v轴值被翻转。这是为了适应Vulkan的坐标系。否则模型和纹理图像将显示为倒置。

数据以交错方式存储后，我们现在可以将其上传到GPU。为此，我们需要创建一个缓冲区来保存顶点和索引数据：

```cpp
VkDeviceSize vBufSize{ sizeof(Vertex) * vertices.size() };
VkDeviceSize iBufSize{ sizeof(uint16_t) * indices.size() };
VkBufferCreateInfo bufferCI{
	.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
	.size = vBufSize + iBufSize,
	.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_INDEX_BUFFER_BIT
};
```

我们没有为顶点和索引使用单独的缓冲区，而是将两者放在同一个缓冲区中。因此，缓冲区的`size`是从顶点和索引向量的大小计算出来的。缓冲区[`usage`](https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html)位掩码组合`VK_BUFFER_USAGE_VERTEX_BUFFER_BIT`和`VK_BUFFER_USAGE_INDEX_BUFFER_BIT`向驱动程序信号指示预期用例。

类似于之前创建图像，我们使用VMA为存储顶点和索引数据分配缓冲区：

```cpp
VmaAllocationCreateInfo vBufferAllocCI{
	.flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT | VMA_ALLOCATION_CREATE_MAPPED_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
VmaAllocationInfo vBufferAllocInfo{};
chk(vmaCreateBuffer(allocator, &bufferCI, &vBufferAllocCI, &vBuffer, &vBufferAllocation, &vBufferAllocInfo));
```

我们再次使用`VMA_MEMORY_USAGE_AUTO`让VMA为缓冲区选择正确的使用标志。这里使用的特定`flags`组合`VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT`和`VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT`确保我们获得位于GPU上（在VRAM中）且可由主机访问的内存类型。虽然可以将顶点和索引存储在CPU内存中，但GPU对它们的访问会慢得多。早期，CPU可访问的VRAM内存类型仅在具有统一内存架构的系统（如移动设备或集成GPU）上可用。但感谢[(Re)BAR/SAM](https://en.wikipedia.org/wiki/PCI_configuration_space#Resizable_BAR)，即使是独立GPU现在也可以将其大部分VRAM映射到主机地址空间，并使其可通过CPU访问。

!!! Note

	没有这一点，我们将不得不在主机上创建一个所谓的"暂存"缓冲区，将数据复制到该缓冲区，然后使用命令缓冲区提交从暂存到GPU端缓冲区的缓冲区复制。这将需要更多的代码。

`VMA_ALLOCATION_CREATE_MAPPED_BIT`为我们提供了一个持久映射的缓冲区，这反过来让我们可以直接将数据复制到VRAM：

```cpp
memcpy(vBufferAllocInfo.pMappedData, vertices.data(), vBufSize);
memcpy(((char*)vBufferAllocInfo.pMappedData) + vBufSize, indices.data(), iBufSize);
```

## CPU和GPU并行性

在图形密集的应用程序中，CPU主要用于向GPU提供工作。当OpenGL发明时，计算机有一个单核CPU。但今天，即使是移动设备也有多个核心，Vulkan让我们可以更明确地控制工作如何在这些核心和GPU之间分配。

这让我们可以在可能的情况下让CPU和GPU并行工作。因此，当GPU仍然忙碌时，我们已经开始在CPU上创建下一个"工作包"。天真的方法是让GPU总是等待CPU（反之亦然），但这会扼杀任何并行性的机会。

!!! Tip

	记住这一点将有助于理解为什么Vulkan中存在[命令缓冲区](#command-buffers)之类的东西，以及为什么我们复制某些资源。

这样做的一个前提是乘以CPU和GPU共享的资源。这样，CPU可以在GPU仍在使用资源*n*时开始更新资源*n+1*。这基本上是双（或多）缓冲，在Vulkan中通常称为"飞行帧"(frames in flight)。

虽然理论上我们可以有许多飞行帧，但每个添加的飞行帧也会增加延迟。所以通常你不会超过2或3个飞行帧。我们在代码的最顶部定义这个：

```cpp
constexpr uint32_t maxFramesInFlight{ 2 };
```

并使用它来调整所有由CPU和GPU共享的资源：

```cpp
std::array<ShaderDataBuffer, maxFramesInFlight> shaderDataBuffers;
std::array<VkCommandBuffer, maxFramesInFlight> commandBuffers;
```

!!! Note

	飞行帧的概念只适用于CPU和GPU共享的资源。仅由GPU使用的资源不必乘以。这适用于例如图像。

## 着色数据缓冲区

我们还希望向我们的[着色器](#the-shader)传递可以在CPU端更改的值，例如来自用户输入。为此，我们将创建可以由CPU写入并由GPU读取的缓冲区。这些缓冲区中的数据对于绘制调用的所有着色器调用保持恒定（统一）。这对GPU来说是一个重要的保证。

我们要传递的数据存储在一个结构中并连续布局，所以我们可以轻松地将其复制到匹配的GPU结构：

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

	重要的是使CPU端和GPU端之间的结构布局匹配。根据使用的数据类型和排列，布局可能看起来相同，但由于着色语言如何对齐结构成员，实际上可能不同。避免这种情况的一种方法，除了手动对齐或填充结构外，是使用Vulkan的[VK_EXT_scalar_block_layout](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_scalar_block_layout.html)或相应的Vulkan 1.2核心特性（两者都是可选的）。

如果我们使用较旧的Vulkan版本，我们现在*将*不得不处理描述符，这是Vulkan的一个基本但部分限制性且难以管理的部分。

但是通过使用Vulkan 1.3的[缓冲区设备地址](https://docs.vulkan.org/guide/latest/buffer_device_address.html)特性，我们可以避免描述符（对于缓冲区）。我们不必通过描述符访问它们，而是可以使用着色器中的指针语法通过其地址访问缓冲区。这不仅使事情更容易理解，而且减少了一些耦合，需要更少的代码。

如[上一章](#cpu-and-gpu-parallelism)所述，我们为最大飞行帧数创建一个着色数据缓冲区。这样我们可以在CPU上更新一个缓冲区，而GPU从另一个缓冲区读取。这确保我们不会遇到任何读/写危险，即CPU在GPU仍在读取值时开始更新值：

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

创建这些缓冲区类似于为我们的网格创建顶点/索引缓冲区。创建信息结构声明我们要通过其设备地址(`VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT`)访问此缓冲区。缓冲区大小必须（至少）匹配我们的CPU数据结构的大小。我们再次使用VMA来处理分配，使用与顶点/索引缓冲区相同的标志，以确保我们获得一个可由CPU和GPU访问的缓冲区。使用`VMA_ALLOCATION_CREATE_MAPPED_BIT`标志确保缓冲区被持久映射，并在`VmaAllocationInfo`结构中给我们一个指向缓冲区的指针。与较旧的API不同，这在Vulkan中是完全没问题的，并且使以后更容易更新缓冲区，因为我们可以保持对缓冲区（内存）的永久指针。

!!! Tip

	与较大的静态缓冲区不同，用于向着色器传递少量数据的缓冲区不必存储在GPU的VRAM中。虽然我们仍然向VMA请求这样的内存类型，回退到CPU端内存不会有问题。

```cpp
	VkBufferDeviceAddressInfo uBufferBdaInfo{
		.sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO,
		.buffer = shaderDataBuffers[i].buffer
	};
	shaderDataBuffers[i].deviceAddress = vkGetBufferDeviceAddress(device, &uBufferBdaInfo);
}
```

为了能够在着色器中访问缓冲区，我们然后获取其设备地址并存储它以供以后访问。

## 同步对象

Vulkan非常明确的另一个领域是[同步](https://docs.vulkan.org/spec/latest/chapters/synchronization.html)。其他API如OpenGL为我们隐式地执行此操作。但在这里，我们需要确保对GPU资源的访问得到适当的保护，以避免可能发生的任何写/读危险，例如CPU开始写入GPU仍在使用的内存。这有点类似于在CPU上进行多线程处理，但更复杂，因为我们需要使这在CPU和GPU之间工作，两者都是非常不同类型的处理单元，以及GPU本身。

!!! Warning

	在Vulkan中正确处理同步可能非常困难，特别是因为错误或缺失的同步可能不会在所有GPU或所有情况下都可见。有时它只在低帧率或移动设备上显示。[验证层](#validation-layers)包括一种使用同步验证预设检查此问题的方法。确保不时启用它并检查报告的任何危险。

我们将在本教程中使用不同的同步手段：

* [栅栏](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-fences)用于从GPU向CPU发出工作完成信号。当我们需要确保CPU和GPU都使用的资源可以自由在CPU上修改时，我们使用它们。
* [二元信号量](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-semaphores)用于控制GPU端（仅）的资源访问。我们使用它们来确保呈现等事情的正确排序。
* [管道屏障](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-pipeline-barriers)用于控制GPU队列内的资源访问。我们使用它们进行图像的布局转换。

栅栏和二元信号量是我们必须创建和存储的对象，而屏障是作为命令发出的，稍后将讨论：

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

创建这些对象没有太多选项。通过设置`VK_FENCE_CREATE_SIGNALED_BIT`标志，栅栏将在信号状态下创建。否则，第一次等待这样的栅栏将导致超时。我们需要每个[飞行帧](#cpu-and-gpu-parallelism)一个栅栏来在GPU和CPU之间同步。用于信号呈现的信号量也是如此。用于信号渲染的信号量数量需要与交换链的图像数量匹配。原因稍后在[命令缓冲区提交](#submit-command-buffer)中解释。

!!! Tip

	对于更复杂的同步设置，[时间线信号量](https://www.khronos.org/blog/vulkan-timeline-semaphores)可以帮助减少冗长性。它们添加了一个带有计数器值的信号量类型，可以增加和等待，也可以由CPU查询以替换栅栏。

## 命令缓冲区

像OpenGL这样的较旧API，你不能在Vulkan中随意向GPU发出命令。相反，我们必须将这些命令记录到[命令缓冲区](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html)中，然后将它们提交到[队列](#queues)。

虽然从应用程序的角度来看这使事情有点复杂，但它有助于驱动程序优化事情，还使应用程序能够在单独的线程上记录命令缓冲区。这是Vulkan允许我们更好地利用CPU和GPU资源的另一个地方。

命令缓冲区必须从[命令池](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandPool.html)分配，这是一个帮助驱动程序优化分配的对象：

```cpp
VkCommandPoolCreateInfo commandPoolCI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
	.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
	.queueFamilyIndex = queueFamily
};
chk(vkCreateCommandPool(device, &commandPoolCI, nullptr, &commandPool));
```

[`VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandPoolCreateFlagBits.html)标志让我们在[记录它们](#record-command-buffer)时隐式重置命令缓冲区。我们还必须指定将从该池分配的命令缓冲区将要提交到的队列族。

!!! Tip

	在更复杂的应用程序中，有多个命令池并不少见。它们创建成本低廉，如果你想从多个线程记录命令缓冲区，每个线程需要这样一个池。

命令缓冲区将在CPU上记录并在GPU上执行，所以我们为最大[飞行帧](#cpu-and-gpu-parallelism)创建一个：

```cpp
VkCommandBufferAllocateInfo cbAllocCI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
	.commandPool = commandPool,
	.commandBufferCount = maxFramesInFlight
};
chk(vkAllocateCommandBuffers(device, &cbAllocCI, commandBuffers.data()));
```

调用[vkAllocateCommandBuffers](https://docs.vulkan.org/refpages/latest/refpages/source/vkAllocateCommandBuffers.html)将从我们刚刚创建的池中分配`commandBufferCount`个命令缓冲区。

## 加载纹理

我们现在将加载用于渲染3D模型的纹理。在Vulkan中，这些是图像，就像交换链或深度图像一样。从GPU的角度来看，图像比缓冲区更复杂，这反映在将它们上传到GPU的冗长性上。

有很多图像格式，但我们将使用[KTX](https://www.khronos.org/ktx/)，这是Khronos的容器格式。与JPEG或PNG等格式不同，它以原生GPU格式存储图像，这意味着我们可以直接上传它们而无需解压缩或转换。它还支持GPU特定功能，如存储mip贴图、3D纹理和立方体贴图。创建KTX图像文件的一个工具是[PVRTexTool](https://developer.imaginationtech.com/solutions/pvrtextool/)。

在该库的帮助下，从磁盘加载这样的文件是微不足道的：

```cpp
for (auto i = 0; i < textures.size(); i++) {
	ktxTexture* ktxTexture{ nullptr };
	std::string filename = "assets/suzanne" + std::to_string(i) + ".ktx";
	ktxTexture_CreateFromNamedFile("assets/suzanne.ktx", KTX_TEXTURE_CREATE_LOAD_IMAGE_DATA_BIT, &ktxTexture);
	...
```

!!! Warning

	我们加载的纹理使用每通道8位的RGBA格式，即使我们不使用alpha通道。你可能想使用RGB来节省内存，但RGB并不广泛支持。如果你在OpenGL中使用这样的格式，驱动程序通常会秘密地将它们转换为RGBA。在Vulkan中，尝试使用不支持的格式只会失败。

创建图像（对象）与我们创建[深度附件](#depth-attachment)的方式非常相似：

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

格式使用`ktxTexture_GetVkFormat`从纹理读取，宽度、高度和[mip级别](https://docs.vulkan.org/spec/latest/chapters/textures.html#textures-level-of-detail-operation)的数量也来自那里。我们所需的`usage`组合意味着我们想要将从磁盘加载的数据传输到此图像（`VK_IMAGE_USAGE_TRANSFER_DST_BIT`）并且（稍后）想要在着色器中从中采样（`VK_IMAGE_USAGE_SAMPLED_BIT`）。我们再次使用VK_IMAGE_LAYOUT_UNDEFINED，因为这是在这种情况下唯一允许的布局（唯一允许的其他格式是VK_IMAGE_LAYOUT_PREINITIALIZED，但这仅适用于线性平铺图像）。再次使用`vmaCreateImage`创建图像，`VMA_MEMORY_USAGE_AUTO`确保我们获得最合适的内存类型（GPU VRAM）。

我们还创建一个视图，通过该视图将访问图像（纹理）。在我们的情况下，我们希望访问整个图像，包括所有mip级别：

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

创建了空图像后，是时候上传数据了。与缓冲区不同，我们不能简单地将数据memcpy到图像。这是因为[最佳平铺](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageTiling.html)以硬件特定的布局存储纹理，我们无法转换到该布局。相反，我们必须创建一个中间缓冲区，我们将数据复制到该缓冲区，然后向GPU发出一个命令，将该缓冲区复制到图像，从而进行转换。

创建该缓冲区与创建[着色数据缓冲区](#shader-data-buffers)非常相似，但有一些细微差别：

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

此缓冲区将用作缓冲区到图像复制的临时源，所以我们需要的唯一标志是[`VK_BUFFER_USAGE_TRANSFER_SRC_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html)。分配再次由VMA处理。

由于缓冲区是用可映射标志创建的，将图像数据放入该缓冲区再次只是一个简单的`memcpy`：

```cpp
memcpy(imgSrcAllocInfo.pMappedData, ktxTexture->pData, ktxTexture->dataSize);
```

接下来，我们需要将图像数据从该缓冲区复制到GPU上的最佳平铺图像。为此，我们必须创建一个命令缓冲区。我们将在[稍后](#record-command-buffer)详细介绍它们如何工作。我们还创建一个栅栏，用于等待命令缓冲区完成执行：

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

然后我们可以开始记录将图像数据带到其目的地所需的命令：

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

乍一看可能有点压倒性，但很容易解释。之前我们了解了最佳平铺图像，其中纹理以硬件特定的布局存储，以便GPU最佳访问。该[布局](https://docs.vulkan.org/spec/latest/chapters/resources.html#resources-image-layouts)还定义了可以对图像执行哪些操作。这就是为什么我们需要根据我们接下来要对图像做什么来更改该布局。这是通过[vkCmdPipelineBarrier2](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdPipelineBarrier2.html)发出的管道屏障完成的。第一个屏障将纹理图像的所有mip级别从初始未定义布局转换为一个允许我们将数据传输到它的布局（`VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`）。然后，我们使用[vkCmdCopyBufferToImage](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdCopyBufferToImage.html)从临时缓冲区复制所有mip级别到图像。最后，我们将mip级别从传输目标转换为我们可以在着色器中读取的布局（`VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL`）。将此命令缓冲区提交到图形队列然后执行所有这些命令。命令缓冲区提交将在[稍后](#submit-command-buffer)深入解释。

!!! Tip

	可以使这更容易的扩展是[VK_EXT_host_image_copy](https://www.khronos.org/blog/copying-images-on-the-host-in-vulkan)，允许直接从CPU复制图像数据而无需使用命令缓冲区和[VK_KHR_unified_image_layouts](https://www.khronos.org/blog/so-long-image-layouts-simplifying-vulkan-synchronisation)，简化图像布局。这些还没有广泛支持，但是使Vulkan更容易使用的未来候选者。

稍后我们将在着色器中采样这些纹理，在那里使用的采样参数由采样器对象定义。我们要平滑的线性过滤，所以我们启用[各向异性过滤](https://docs.vulkan.org/spec/latest/chapters/textures.html#textures-texel-anisotropic-filtering)以减少模糊和锯齿。我们还设置最大LOD以使用所有mip级别：

```cpp
VkSamplerCreateInfo samplerCI{
	.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
	.magFilter = VK_FILTER_LINEAR,
	.minFilter = VK_FILTER_LINEAR,
	.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR,
	.anisotropyEnable = VK_TRUE,
	.maxAnisotropy = 8.0f, // 8是广泛支持的最大各向异性值
	.maxLod = (float)ktxTexture->numLevels,
};
chk(vkCreateSampler(device, &samplerCI, nullptr, &textures[i].sampler));
```

最后，我们清理并存储该纹理的描述符相关信息以供以后使用：

```cpp
ktxTexture_Destroy(ktxTexture);
textureDescriptors.push_back({
    .sampler = textures[i].sampler,
    .imageView = textures[i].view,
    .imageLayout = VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL
});
```

现在我们已经上传了纹理图像，将它们放入正确的布局，并且知道如何采样它们，我们需要一种方法让GPU在着色器中访问它们。从GPU的角度来看，图像比缓冲区更复杂，因为GPU需要更多关于它们的外观以及如何访问它们的信息。这就是[描述符](https://docs.vulkan.org/spec/latest/chapters/descriptorsets.html)所必需的地方，这些句柄表示（描述，因此得名）着色器资源。

在较早的Vulkan版本中，我们也必须对缓冲区使用它们，但如[着色数据缓冲区](#shader-data-buffers)章节所述，缓冲区设备地址使我们免于这样做。对于图像，还没有易于使用或广泛可用的等效物。

虽然描述符处理仍然是最冗长的部分之一，但使用[描述符索引](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html)，可以显著简化这一点或使其更容易扩展。使用该特性，我们可以采用"无绑定"设置，其中所有纹理都放入一个大数组中，并在[着色器](#the-shader)中索引，而不是必须为每个纹理创建和绑定描述符集。为了演示这如何工作，我们将加载多个纹理。无论你使用多少纹理（在GPU支持的范围内），这种方法都可以扩展。

首先，我们以描述符集布局的形式定义我们的应用程序和着色器之间的接口：

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

由于我们只对图像使用描述符，我们只有一个绑定。[VkDescriptorSetLayoutBindingFlagsCreateInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorSetLayoutBindingFlagsCreateInfo.html)用于在该绑定中启用可变数量的描述符，作为描述符索引的一部分，并通过`pNext`传递。我们组合纹理图像和采样器（见下文），所以绑定的类型需要是[`VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER`](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorType.html)。该布局中将有与我们加载的纹理一样多的描述符，我们只需要从片段着色器访问它，所以我们设置`stageFlags`为`VK_SHADER_STAGE_FRAGMENT_BIT`。调用[vkCreateDescriptorSetLayout](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateDescriptorSetLayout.html)将创建一个具有此配置的描述符集布局。我们需要它来分配描述符，并在[管道创建](#graphics-pipeline)时定义着色器接口。

!!! Tip

	有些情况下，你可以分离图像和采样器，例如，如果你有很多图像，不想浪费内存为每个图像设置采样器，或者你想动态使用不同的采样选项。在这种情况下，你会使用两个池大小，一个用于`VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE`，一个用于`VK_DESCRIPTOR_TYPE_SAMPLER`。

类似于命令缓冲区，描述符从描述符池中分配：

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

我们必须在这里预先指定要分配的描述符类型的数量。我们需要与加载的纹理一样多的组合图像和采样器描述符。我们还必须指定要通过`maxSets`分配多少描述符集（**不是**描述符）。这是一个，因为使用描述符索引，我们使用一个组合图像和采样器数组。它也只由GPU访问，所以不需要每个最大飞行帧复制它。正确获取池大小很重要，因为超出请求计数的分配将失败。

接下来，我们从该池中分配描述符集。虽然描述符集布局定义了接口，但描述符包含实际的描述符数据。布局和集分开的原因是因为你可以混合布局并将它们重新用于不同的描述符集。

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

类似于描述符集布局创建，我们必须通过`pNext`中的[VkDescriptorSetVariableDescriptorCountAllocateInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorSetVariableDescriptorCountAllocateInfo.html)传递描述符索引设置。

由[vkAllocateDescriptorSets](https://docs.vulkan.org/refpages/latest/refpages/source/vkAllocateDescriptorSets.html)分配的描述符集基本上未初始化，需要在着色器中访问之前用实际数据支持：

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

[VkDescriptorImageInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorImageInfo.html)指的是我们上面加载的纹理的描述符数组与采样器组合在`pImageInfo`中。调用[vkUpdateDescriptorSets](https://docs.vulkan.org/refpages/latest/refpages/source/vkUpdateDescriptorSets.html)会将该信息放入描述符集的第一个（在我们的情况下也是唯一的）绑定槽中。

## 加载着色器

如前所述，我们将使用[Slang语言](https://github.com/shader-slang)来编写在GPU上运行的着色器。但是Vulkan不能直接加载用这种语言（或GLSL或HLSL）编写的着色器。它期望它们采用SPIR-V中间格式。为此，我们需要先从Slang编译到SPIR-V。有两种方法可以做到这一点：使用Slang的命令行编译器进行离线编译，或者使用Slang的库在运行时编译。

我们将选择后者，因为这使更新着色器更容易。使用离线编译，你必须在每次更改着色器时重新编译它们，或者找到一种方法让构建系统为你做这件事。使用运行时编译，我们在运行代码时总是使用最新的着色器版本。

要编译Slang着色器，我们首先创建一个全局Slang会话，这是我们的应用程序和Slang库之间的连接：

```cpp
slang::createGlobalSession(slangGlobalSession.writeRef());
```

接下来，我们创建一个会话来定义我们的编译范围。我们要编译到SPIR-V，所以我们将目标`format`设置为`SLANG_SPIRV`。我们使用[SPIR-V 1.4](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_spirv_1_4.html)作为着色器特性的基线。自Vulkan 1.2以来，这已成为核心，所以在我们的情况下保证得到支持。我们还将`defaultMatrixLayoutMode`更改为列主布局，以匹配我们稍后用于构造矩阵的GLM库的布局：

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

由`createSession`创建的会话然后可以用于获取Slang着色器的SPIR-V表示。为此，我们首先使用`loadModuleFromSource`从文件加载文本着色器，然后使用`getTargetCode`将我们着色器中的所有入口点编译为SPIR-V：

```cpp
Slang::ComPtr<slang::IModule> slangModule{
    slangSession->loadModuleFromSource("triangle", "assets/shader.slang", nullptr, nullptr)
};
Slang::ComPtr<ISlangBlob> spirv;
slangModule->getTargetCode(0, spirv.writeRef());
```

要在图形管道中使用我们的着色器（见下文），我们需要创建一个着色器模块。这些是编译的SPIR-V着色器的容器。要创建这样的模块，我们将由Slang编译的SPIR-V传递给[`vkCreateShaderModule`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateShaderModule.html)：

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

	[VK_KHR_maintenance5](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_maintenance5.html)扩展，该扩展在Vulkan 1.4中成为核心，已弃用着色器模块。它允许直接将`VkShaderModuleCreateInfo`传递到管道的着色器阶段创建信息。

## 着色器

虽然着色语言不如CPU编程语言强大，但它们仍然可以处理复杂场景。我们的着色器有意保持简单：

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
    // 计算光照所需的视图向量
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
    // 从纹理采样
    float3 color = textures[NonUniformResourceIndex(input.InstanceIndex)].Sample(input.UV).rgb * input.Factor;
    return float4(diffuse * color.rgb + specular, 1.0);
}
```

!!! Tip

	Slang让我们将所有着色器阶段放入一个文件中。这消除了复制着色器接口或必须将其放入共享包含文件的需要。它还使着色器更容易阅读（和编辑）。

它包含两个着色器阶段，首先定义不同阶段使用的结构。`ShaderData`结构匹配[CPU端](#shader-data-buffers)定义的着色器数据结构的布局。

首先是顶点着色器，由`[shader("vertex")]`属性标记。它接受定义为`VSInput`的顶点，匹配[图形管道](#graphics-pipeline)的顶点布局。顶点着色器将为每个[绘制](#record-command-buffer)的顶点调用。由于我们使用缓冲区设备地址，我们作为指针传递和访问UBO。由于我们绘制3D模型的多个实例，并且想为每个实例使用不同的矩阵，我们使用内置的`SV_VulkanInstanceID`系统值来索引模型矩阵。我们还想突出显示所选模型，所以如果当前实例与该选择匹配，我们将不同的颜色因子传递给片段着色器。

其次是片段着色器，由`[shader("fragment")]`属性标记。首先，我们使用从顶点着色器传递的值计算一些基本光照，使用[Phong反射模型](https://en.wikipedia.org/wiki/Phong_reflection_model)。然后，为了演示描述符索引，我们使用实例索引从纹理数组（`Sampler2D textures[]`）中读取，最后将其与光照计算结合。这被写入当前颜色附件。

## 图形管道

Vulkan与OpenGL有很大不同的另一个领域是状态管理。OpenGL是一个巨大的状态机，该状态可以随时更改。这使得驱动程序很难优化事情。Vulkan通过引入管道状态对象从根本上改变了这一点。它们在"编译"的管道对象中提供完整的管道状态集，给驱动程序一个优化它们的机会。这些对象还允许在例如单独的线程中创建管道对象。如果你需要不同的管道状态，你必须创建一个新的管道状态对象。

!!! Note

	Vulkan中有*一些*状态可以是动态的。主要是基本状态，如视口和剪刀设置。它们是动态的对驱动程序来说不是问题。有几个扩展使额外的状态动态化，但我们不会在这里使用它们。

Vulkan支持特定于用例的[管道类型](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineBindPoint.html)，如图形、计算、光线追踪。因此，设置管道取决于我们要实现什么。在我们的情况下，那是图形（也称为[光栅化](https://en.wikipedia.org/wiki/Rasterisation)），所以我们将创建一个图形管道。

首先，我们创建一个管道布局。这定义了管道和我们的着色器之间的接口。管道布局是单独的对象，因为你可以混合和匹配它们以与其他管道一起使用：

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

[`pushConstantRange`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPushConstantRange.html)定义了一个我们可以直接推送到着色器的值范围，而不必通过缓冲区。我们使用这些来传递指向着色数据缓冲区缓冲区的指针（稍后会详细介绍）。描述符集布局（`pSetLayouts`）定义了到着色器资源的接口。在我们的情况下，这只是传递纹理图像描述符的一个布局。调用[`vkCreatePipelineLayout`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCreatePipelineLayoutCreateInfo.html)将创建我们然后可以用于管道的管道布局。

管道和着色器之间接口的另一个部分是顶点数据的布局。在[网格加载章节](#loading-meshes)中，我们定义了一个基本的顶点结构，现在我们需要在Vulkan术语中指定它。我们使用单个顶点缓冲区，所以我们需要一个[顶点绑定点](https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputBindingDescription.html)。`stride`匹配我们的顶点结构的大小，因为我们的顶点直接在内存中相邻存储。`inputRate`是每个顶点，意味着数据指针为每个读取的顶点前进：

```cpp
VkVertexInputBindingDescription vertexBinding{
	 .binding = 0,
	 .stride = sizeof(Vertex),
	 .inputRate = VK_VERTEX_INPUT_RATE_VERTEX
};
```

接下来，我们指定位置、法线和纹理坐标的[顶点属性](https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputAttributeDescription.html)如何在内存中布局。这完全匹配我们的CPU端顶点结构：

```cpp
std::vector<VkVertexInputAttributeDescription> vertexAttributes{
	{ .location = 0, .binding = 0, .format = VK_FORMAT_R32G32B32_SFLOAT },
	{ .location = 1, .binding = 0, .format = VK_FORMAT_R32G32B32_SFLOAT, .offset = offsetof(Vertex, normal) },
	{ .location = 2, .binding = 0, .format = VK_FORMAT_R32G32_SFLOAT, .offset = offsetof(Vertex, uv) },
};
```
!!! Tip

	在着色器中访问顶点的另一个选项是缓冲区设备地址。那样我们将跳过传统的顶点属性，并使用指针在着色器中手动获取它们。这称为"顶点拉动"。在某些设备上这可能更慢，所以我们坚持传统方式。

现在我们开始填充创建管道所需的许多`VkPipeline*CreateInfo`结构。我们不会详细解释所有这些，你可以在[规范](https://docs.vulkan.org/refpages/latest/refpages/source/VkGraphicsPipelineCreateInfo.html)中阅读它们。它们都类似，描述管道的特定部分。

首先是我们要刚刚定义的[顶点输入](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineVertexInputStateCreateInfo.html)的管道状态：

```cpp
VkPipelineVertexInputStateCreateInfo vertexInputState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
	.vertexBindingDescriptionCount = 1,
	.pVertexBindingDescriptions = &vertexBinding,
	.vertexAttributeDescriptionCount = static_cast<uint32_t>(vertexAttributes.size()),
	.pVertexAttributeDescriptions = vertexAttributes.data(),
};
```

另一个直接连接到我们的顶点数据的结构是[输入程序集状态](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineInputAssemblyStateCreateInfo.html)。它定义了如何[程序集化](https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html)图元。我们想要渲染一个单独的三角形列表，所以我们使用[`VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html)：

```cpp
VkPipelineInputAssemblyStateCreateInfo inputAssemblyState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
	.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
};
```

任何管道的重要组成部分是我们想要使用的[着色器](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineShaderStageCreateInfo.html)以及它们映射到的管道阶段。只有一组着色器是我们只需要一个管道的原因。多亏了Slang，我们在一个着色器模块中获得所有阶段：

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

	如果你想使用不同的着色器（或着色器组合），你必须创建多个管道。[VK_EXT_shader_objects](https://www.khronos.org/blog/you-can-use-vulkan-without-pipelines-today)将这些着色器阶段变成单独的对象，并为此API部分添加了更多灵活性。

接下来，我们配置[视口状态](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineViewportStateCreateInfo.html)。我们使用一个视口和一个剪刀，我们也希望它们是动态状态，这样如果其中任何一个发生变化，例如调整窗口大小时，我们不必重新创建管道。这是自Vulkan 1.0以来存在的少数动态状态之一：

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

由于我们要使用[深度缓冲](#depth-attachment)，我们配置[深度/模板状态](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineDepthStencilStateCreateInfo.html)以启用深度测试和写入，并设置比较操作，使更接近查看器的片段通过深度测试：

```cpp
VkPipelineDepthStencilStateCreateInfo depthStencilState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
	.depthTestEnable = VK_TRUE,
	.depthWriteEnable = VK_TRUE,
	.depthCompareOp = VK_COMPARE_OP_LESS_OR_EQUAL
};
```

以下状态告诉管道我们要使用动态渲染而不是繁琐的渲染通道对象。与渲染通道不同，设置这个相当简单，并且还消除了管道和渲染通道之间的紧密耦合。对于动态渲染，我们只需要指定我们计划使用的附件的数量和格式（稍后）：

```cpp
VkPipelineRenderingCreateInfo renderingCI{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO,
	.colorAttachmentCount = 1,
	.pColorAttachmentFormats = &imageFormat,
	.depthAttachmentFormat = depthFormat
};
```

!!! Note

	由于此功能是在Vulkan生命周期的后期添加的，因此管道创建信息中没有为此的专用成员。我们通过`pNext`传递它（见下文）

我们不使用以下状态，但必须指定它们，并且还需要有一些合理的默认值。所以我们将[混合](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineColorBlendStateCreateInfo.html)、[光栅化](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineRasterizationStateCreateInfo.html)和[多重采样](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineMultisampleStateCreateInfo.html)设置为默认值：

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

有了所有相关的管道状态创建结构正确设置，我们将它们连接起来最终创建我们的图形管道：

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

成功调用[`vkCreateGraphicsPipelines`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateGraphicsPipelines.html)后，我们的图形管道准备好用于渲染。

## 渲染循环

达到这一点需要相当大的努力，但我们现在准备好实际在屏幕上"绘制"某些内容。像之前很多内容一样，这在Vulkan中既是显式的又是间接的。与早期计算机图形的工作方式相比，如今在屏幕上显示某些内容是一件复杂的事情。特别是对于必须支持如此多不同平台和设备的API。

这把我们带到了渲染循环，在其中我们将处理用户输入，渲染我们的场景，更新着色器值，并确保所有这些在CPU和GPU之间以及GPU本身上正确同步：

```cpp
uint64_t lastTime{ SDL_GetTicks() };
bool quit{ false };
while (!quit) {
	// 等待栅栏
	// 获取下一个图像
	// 更新着色器数据
	// 记录命令缓冲区
	// 提交命令缓冲区
	// 呈现图像
	// 轮询事件
}
```

只要窗口保持打开，循环就会执行。SDL还为我们提供了精确的[计时函数](https://wiki.libsdl.org/SDL3/SDL_GetTicks)，我们用它来测量经过的时间以进行帧率无关的计算。

循环内部发生了很多事情，所以现在我们将分别查看每个部分。

### 等待栅栏

如[CPU和GPU并行性](#cpu-and-gpu-parallelism)中所讨论的，我们可以重叠CPU和GPU工作的一个领域是命令缓冲区记录。我们希望CPU在GPU仍在处理上一个命令缓冲区时开始记录下一个命令缓冲区。

为此，我们等待GPU处理的最后一帧的栅栏完成执行：

```cpp
chk(vkWaitForFences(device, 1, &fences[frameIndex], true, UINT64_MAX));
chk(vkResetFences(device, 1, &fences[frameIndex]));
```

调用[vkWaitForFences](https://docs.vulkan.org/refpages/latest/refpages/source/vkWaitForFences.html)将在CPU上等待，直到GPU发出它已完成使用该栅栏提交的所有工作的信号。我们使用故意大的超时值`UINT64_MAX`。由于栅栏仍处于信号状态，我们还需要[重置](https://docs.vulkan.org/refpages/latest/refpages/source/vkResetFences.html)它以进行下一次提交。

!!! Note

	我们对图形操作允许的时间长短没有要求，所以我们基本上不关心超时。我们不执行任何特别复杂的任务，栅栏通常会在几毫秒内发出信号。此外，大多数操作系统实现功能，如果图形任务花费太长时间，则重置GPU。

### 获取下一个图像

由于我们不直接控制[交换链图像](#swapchain)，我们需要"请求"（获取）交换链以获取在此帧中要使用的下一个索引：

```cpp
chkSwapchain(vkAcquireNextImageKHR(device, swapchain, UINT64_MAX, presentSemaphores[frameIndex], VK_NULL_HANDLE, &imageIndex));
```

重要的是使用[vkAcquireNextImageKHR](https://docs.vulkan.org/refpages/latest/refpages/source/vkAcquireNextImageKHR.html)返回的图像索引来访问交换链图像。这是因为不能保证图像是按连续顺序获取的。这就是我们有两个索引的原因之一。

我们还向此函数传递一个[信号量](#synchronization-objects)，稍后将在命令缓冲区提交时使用。

!!! Note

	我们使用`chk`函数的变体来检查与呈现相关的调用的返回值。这是由于[VK_ERROR_OUT_OF_DATE_KHR](https://docs.vulkan.org/spec/latest/chapters/fundamentals.html#VkResult)，当表面不再与交换链兼容时返回此错误。这可能发生在某些平台上，例如，如果显示方向改变。为了防止应用程序在这些情况下退出，我们在`chkSwapchain`中显式处理此错误。不是退出，我们为下一帧重新创建交换链。

### 更新着色器数据

我们希望下一帧使用最新的用户输入。在等待栅栏后，现在这样做是安全的。为此，我们使用glm从当前数据更新矩阵：

```cpp
shaderData.projection = glm::perspective(glm::radians(45.0f), (float)window.getSize().x / (float)window.getSize().y, 0.1f, 32.0f);
shaderData.view = glm::translate(glm::mat4(1.0f), camPos);
for (auto i = 0; i < 3; i++) {
	auto instancePos = glm::vec3((float)(i - 1) * 3.0f, 0.0f, 0.0f);
	shaderData.model[i] = glm::translate(glm::mat4(1.0f), instancePos) * glm::mat4_cast(glm::quat(objectRotations[i]));
}
```

一个简单的`memcpy`到着色数据缓冲区的持久映射指针就足以使其可用于GPU（以及我们的着色器）：

```cpp
memcpy(shaderDataBuffers[frameIndex].allocationInfo.pMappedData, &shaderData, sizeof(ShaderData));
```

这有效是因为[着色数据缓冲区](#shader-data-buffers)存储在可由CPU（用于写入）和GPU（用于读取）访问的内存类型中。通过前面的栅栏同步，我们还确保CPU不会在GPU完成从该着色数据缓冲区读取之前开始写入它。

### 记录命令缓冲区

现在我们可以开始记录实际的GPU工作项。我们需要其中的许多东西已经讨论过，所以虽然这将有很多代码，但应该很容易跟随。如[命令缓冲区](#command-buffers)中所述，命令不是直接在Vulkan中发出到GPU，而是记录到命令缓冲区。这正是我们要做的：记录单个渲染帧的命令。

你可能想预记录命令缓冲区并在需要重新记录之前重用它们。然而，这使事情不必要地复杂，因为你必须实现与CPU/GPU并行性一起工作的更新逻辑。而且由于记录命令缓冲区相对较快，如果需要可以卸载到其他CPU线程，每帧记录它们完全没问题。

!!! Note

	记录到命令缓冲区中的命令以`vkCmd`开头。它们不直接执行，只有当命令缓冲区提交到队列（GPU时间线）时才执行。这也解释了为什么这些命令不返回结果。初学者的一个常见错误是将这些命令与在CPU时间线上立即执行的命令混合。重要的是要记住存在这两个不同的时间线。

命令缓冲区有一个我们必须遵守的[生命周期](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html#commandbuffers-lifecycle)。例如，我们不能在它处于可执行状态时向它记录命令。这也由[验证层](#validation-layers)检查，如果我们错误使用它们，会通知我们。

首先，我们需要将命令缓冲区移动到初始状态。这是通过[重置它](https://docs.vulkan.org/refpages/latest/refpages/source/vkResetCommandBuffer.html)完成的，现在这样做是安全的，因为我们之前等待了栅栏以确保它不再处于挂起状态：

```cpp
auto cb = commandBuffers[frameIndex];
chk(vkResetCommandBuffer(cb, 0));
```

一旦重置，我们可以开始记录命令缓冲区：

```cpp
VkCommandBufferBeginInfo cbBI {
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
	.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
};
chk(vkBeginCommandBuffer(cb, &cbBI));
```

[`VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandBufferUsageFlagBits.html)标志影响生命周期在执行后如何移动到无效状态，并且可以被驱动程序用作优化提示。调用[vkBeginCommandBuffer](https://docs.vulkan.org/refpages/latest/refpages/source/vkBeginCommandBuffer.html)后，它将命令缓冲区移动到记录状态，我们可以开始记录实际命令。

在渲染期间，颜色信息将被写入当前的[交换链图像](#swapchain)，深度信息将被写入[深度图像](#depth-attachment)。如我们在[加载纹理](#loading-textures)中所学，最佳平铺图像需要处于正确布局以用于其预期用例。因此，第一步是为两者发出布局转换：

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

不仅[图像内存屏障](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-dependencies)转换布局，它们还确保这在正确的[管道阶段](https://docs.vulkan.org/spec/latest/chapters/pipelines.html#pipelines-block-diagram)发生，在命令缓冲区内强制排序。类似于我们使用的其他同步原语，这些是必要的，以确保GPU例如不会在一个管道阶段写入图像，而前一个管道阶段仍在从它读取。它们还使写入对后续阶段可见。`srcStageMask`是要等待的管道阶段，`srcAccessMask`定义要使其可用的写入。`dstStageMask`和`dstAccessMask`定义在哪里以及使哪些写入可见。

!!! Note

	可用和可见可能听起来像是一回事，但它们不是。这是由于CPU/GPU的工作方式以及它们如何与缓存交互。可用意味着数据准备好用于未来的内存操作（例如缓存刷新）。可见意味着数据实际上对来自消费阶段的读取可见。

*第一个屏障*将当前交换链图像*转换到*[布局](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html)（`newLayout`），以便我们可以将其用作渲染的颜色附件。同样，*第二个屏障*将深度图像*转换到*布局，以便我们可以将其用作渲染的深度附件。两者都*从*未定义布局（`oldLayout`）转换。这是因为我们不需要这些图像中的任何先前内容。

!!! Tip

	`VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL`布局是Vulkan 1.3的核心特性，它将所有类型的附件布局组合成一个。这简化了图像屏障。

调用[vkCmdPipelineBarrier2](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdPipelineBarrier2.html)然后将这两个屏障插入到当前命令缓冲区中。

有了正确布局的附件，是时候定义我们将如何使用它们了。如前所述，我们将使用[动态渲染](https://www.khronos.org/blog/streamlining-render-passes)，而不是Vulkan 1.0中繁琐的渲染通道对象。

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

我们为用作颜色附件的交换链图像和用作深度附件的深度图像设置一个[VkRenderingAttachmentInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkRenderingAttachmentInfo.html)。两者都将在渲染通道开始时清除到各自的`clearValue`，`loadOp`设置为`VK_ATTACHMENT_LOAD_OP_CLEAR`。颜色附件的`storeOp`配置为保留其内容，因为我们仍然需要它们呈现到屏幕。一旦完成渲染，我们不需要深度信息，所以我们真的不关心渲染通道后其内容发生了什么。两者的布局必须匹配我们之前转换它们的布局。

调用[vkCmdBeginRendering](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdBeginRendering.html)将使用上述附件配置开始我们的动态渲染通道实例：

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

在此渲染通道实例内，我们终于可以开始记录GPU命令。记住这些还没有发出到GPU，只是记录到当前命令缓冲区。

我们首先设置[视口](https://docs.vulkan.org/spec/latest/chapters/vertexpostproc.html#vertexpostproc-viewport)来定义我们的渲染区域。我们总是希望它是整个窗口。对于[剪刀](https://docs.vulkan.org/spec/latest/chapters/fragops.html#fragops-scissor)区域也是如此。两者都是我们在[管道创建](#graphics-pipeline)时启用的动态状态的一部分，所以我们可以调整它们在命令缓冲区内，而不必在每次窗口调整大小时重新创建图形管道：

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

接下来是绑定参与渲染3D对象的资源。[图形管道](#graphics-pipeline)，还包括我们的顶点和片段着色器，以及我们的[纹理图像](#loading-textures)数组的描述符集和我们的[3D网格](#loading-meshes)的顶点和索引缓冲区：

```cpp
vkCmdBindPipeline(cb, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);
VkDeviceSize vOffset{ 0 };
vkCmdBindDescriptorSets(cb, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &descriptorSetTex, 0, nullptr);
vkCmdBindVertexBuffers(cb, 0, 1, &vBuffer, &vOffset);
vkCmdBindIndexBuffer(cb, vBuffer, vBufSize, VK_INDEX_TYPE_UINT16);
```

我们还想访问[着色数据缓冲区](#shader-data-buffer)中的数据。我们选择使用缓冲区设备地址而不是通过描述符，所以我们通过推常量将当前帧的着色数据缓冲区的地址传递给着色器：

```cpp
vkCmdPushConstants(cb, pipelineLayout, VK_SHADER_STAGE_VERTEX_BIT, 0, sizeof(VkDeviceAddress), &shaderDataBuffers[frameIndex].deviceAddress);
```

!!! Note

	这些`vkCmd*`调用（以及许多其他调用）设置当前命令缓冲区状态。这意味着它们在此命令缓冲区内的多个绘制调用中持续存在。所以，例如，如果你想发出第二个绘制调用，使用相同的管道但不同的描述符集，你只需要用另一个集调用`vkCmdBindDescriptorSets`，同时保持其余状态。

有了这些，我们*终于*准备好发出实际的绘制命令。有了我们到目前为止所做的所有工作，这只是一个命令：

```cpp
vkCmdDrawIndexed(cb, indexCount, 3, 0, 0, 0);
```

此调用[vkCmdDrawIndexed](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdDrawIndexed.html)将从当前绑定的索引和顶点缓冲区绘制indexCount / 3个三角形。我们还想绘制3D网格的多个实例，所以我们将实例计数（第三个参数）设置为3，我们在[顶点着色器](#the-shader)中使用它来索引[模型矩阵](#shader-data-buffers)。

我们现在[完成](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdEndRendering.html)当前渲染通道：

```cpp
vkCmdEndRendering(cb);
```

并将我们刚刚用作附件（以输出颜色值）的交换链图像转换为[呈现](#present-image)所需的布局：

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

我们不需要深度附件的屏障，因为我们不在此渲染通道之外使用它。

最后，我们[结束记录](https://docs.vulkan.org/refpages/latest/refpages/source/vkEndCommandBuffer.html)命令缓冲区：

```cpp
vkEndCommandBuffer(cb);
```

这将它移动到[可执行状态](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html#commandbuffers-lifecycle)。这是下一步的要求。

### 提交命令缓冲区

为了执行我们刚刚记录的命令，我们需要将命令缓冲区提交到匹配的队列。在实际应用程序中，拥有不同类型的多个队列以及更复杂的提交模式并不少见。但我们只使用图形命令（没有计算或光线追踪），因此也只有一个图形队列，我们将当前帧的命令缓冲区提交到该队列：

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

[`VkSubmitInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkSubmitInfo.html)结构需要一些解释，特别是关于同步。之前，我们了解了我们需要在CPU和GPU之间以及GPU本身正确同步工作的[同步原语](#synchronization-objects)。这就是所有这些结合在一起的地方。

`pWaitSemaphores`中的信号量确保提交的命令缓冲区在当前帧的呈现完成之前不会开始执行。`pWaitDstStageMask`中的管道阶段将使该等待在管道的颜色附件输出阶段发生，因此（理论上）GPU可能已经开始在管道中在此之前的部分上工作，例如获取顶点。另一方面，`pSignalSemaphores`中的信号信号量是一个信号量，一旦命令缓冲区执行完成，GPU就会发出信号。这种组合确保不会发生读/写危险，使GPU读取或写入仍在使用的资源。

注意对呈现信号量使用`frameIndex`和对渲染信号量使用`imageIndex`的区别。这是因为`vkQueuePresentKHR`（见下文）没有某种扩展（尚未在任何地方可用）就无法发信号。为了解决这个问题，我们解耦了两种信号量类型，并为每个交换链图像使用一个呈现信号量。对此的深入解释可以在[Vulkan指南](https://docs.vulkan.org/guide/latest/swapchain_semaphore_reuse.html)中找到。

!!! Warning

	提交可以有多个等待和信号信号量以及等待阶段。在比我们的更复杂的应用程序（可能混合图形和计算）中，重要的是保持同步范围尽可能窄，以允许GPU重叠工作。这是在Vulkan中最难正确处理的部分之一。可以使用[验证层](#validation-layers)检测错误，可以使用供应商特定的图形分析器检查性能。

一旦提交了工作，我们可以为下一次渲染循环迭代计算帧索引：

```cpp
frameIndex = (frameIndex + 1) % maxFramesInFlight;
```

### 呈现图像

将我们的渲染结果带到屏幕的最后一步是呈现我们用作颜色附件的当前交换链图像：

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

调用[vkQueuePresentKHR](https://docs.vulkan.org/refpages/latest/refpages/source/vkQueuePresentKHR.html)将在等待渲染信号量后将图像排队进行呈现。这确保在我们的渲染命令完成之前不会呈现图像。

### 轮询事件

最后但同样重要的是，我们处理操作系统的事件队列。多亏了SDL，这段代码是平台无关的。事件处理是在渲染循环内的附加循环中完成的，我们在其中调用SDL的[事件轮询函数](https://wiki.libsdl.org/SDL3/SDL_PollEvent)，直到处理完所有事件。我们只处理我们感兴趣的事件类型：

```cpp
float elapsedTime{ (SDL_GetTicks() - lastTime) / 1000.0f };
lastTime = SDL_GetTicks();
for (SDL_Event event; SDL_PollEvent(&event);) {

	// 如果应用程序即将关闭，则退出循环
	if (event.type == SDL_EVENT_QUIT) {
		quit = true;
		break;
	}

	// 使用鼠标拖动旋转所选对象
	if (event.type == SDL_EVENT_MOUSE_MOTION) {
		if (event.button.button == SDL_BUTTON_LEFT) {
			objectRotations[shaderData.selected].x -= (float)event.motion.yrel * elapsedTime;
			objectRotations[shaderData.selected].y += (float)event.motion.xrel * elapsedTime;
		}
	}

	// 使用鼠标滚轮缩放
	if (event.type == SDL_EVENT_MOUSE_WHEEL) {
		camPos.z += (float)event.wheel.y * elapsedTime * 10.0f;
	}

	// 选择活动模型实例
	if (event.type == SDL_EVENT_KEY_DOWN) {
		if (event.key.key == SDLK_PLUS || event.key.key == SDLK_KP_PLUS) {
			shaderData.selected = (shaderData.selected < 2) ? shaderData.selected + 1 : 0;
		}
		if (event.key.key == SDLK_MINUS || event.key.key == SDLK_KP_MINUS) {
			shaderData.selected = (shaderData.selected > 0) ? shaderData.selected - 1 : 2;
		}
	}

	// 窗口调整大小
	if (event.type == SDL_EVENT_WINDOW_RESIZED) {
		updateSwapchain = true;
	}
}
```

我们希望在我们的应用程序中有一些交互性。为此，我们在`SDL_EVENT_MOUSE_MOTION`事件中基于左键按下时的鼠标移动计算当前所选模型实例的旋转。鼠标滚轮在`SDL_EVENT_MOUSE_WHEEL`中也是如此，以允许放大和缩小摄像机。`SDL_EVENT_KEY_DOWN`事件让我们使用加号和减号键在模型实例之间切换。

当我们的应用程序要关闭时，无论以何种方式，都会调用`SDL_EVENT_QUIT`事件。在这种情况下，我们将`quit`设置为true，退出外部渲染循环并跳转到代码的[清理](#cleaning-up)部分。

虽然这是可选的，而且游戏通常不实现，但我们还通过`SDL_EVENT_WINDOW_RESIZED`事件处理调整大小，这需要重新创建交换链和相关资源。

### 重新创建交换链

当窗口调整大小或其表面变为[过时](#acquire-next-image)时，需要重新创建交换链。如果这些操作中的任何一个请求更新交换链，我们重新创建它：

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

这乍一看很令人生畏，但主要是我们之前用于创建交换链和深度图像的代码。在重新创建这些之前，我们调用[vkDeviceWaitIdle](https://docs.vulkan.org/refpages/latest/refpages/source/vkDeviceWaitIdle.html)等待，直到GPU完成了所有未完成的操作。这确保这些对象中没有一个仍在GPU使用。

一个重要的区别是设置交换链创建信息的`oldSwapchain`成员。这在重新创建期间是必要的，以允许应用程序继续呈现任何已获取的图像。记住我们不控制这些，因为它们由交换链（和操作系统）拥有。除此之外，这只是销毁现有对象（`vkDestroy*`）并像我们之前那样创建它们的新版本，只是使用窗口的新大小。

## 清理

销毁Vulkan资源与创建它们一样显式。理论上，你可以退出应用程序而不这样做，并让操作系统为你清理。但适当地清理是你应该做的事情，所以我们这样做。我们再次调用vkDeviceWaitIdle以确保我们要销毁的GPU资源中没有一个仍在使用。一旦该调用成功完成，我们可以开始清理我们在应用程序中创建的所有Vulkan GPU对象：

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

命令的顺序只对VMA分配器、设备和实例很重要。这些应该只在从它们创建的所有对象之后销毁。实例应该最后删除，这样我们就会通过验证层（启用时）通知我们忘记正确删除的每个对象。你不必显式销毁的一个资源是命令缓冲区。调用[vkDestroyCommandPool](https://docs.vulkan.org/refpages/latest/refpages/source/vkDestroyCommandPool.html)将隐式释放从该池分配的所有命令缓冲区。

## 结语

现在，你应该对如何创建执行光栅化并利用最新API版本和特性的Vulkan应用程序有基本的了解。Vulkan仍然是一个相对冗长的API，这与其显式的低级设计固有的。虽然我们仍然需要大量代码来在Vulkan中运行某些东西，但它更容易理解，更灵活，为更复杂的应用程序提供了坚实的基础。

从更广泛的角度来看，2026年的Vulkan比以往任何时候都支持更广泛的用例。除了光栅化和计算之外，它还提供硬件加速光线追踪、视频编码和解码、机器学习和安全关键领域的功能。

如果你正在寻找更多资源，请查看[Vulkan文档站点](https://docs.vulkan.org/)。它将多个Vulkan文档资源（如规范、教程和示例）组合到一个方便的单一站点中。
