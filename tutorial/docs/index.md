<!--
Copyright (c) 2025-2026, Sascha Willems
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# How to Vulkan in 2026

!!! Note

	While the tutorial is mostly content complete, it's still a preview and not yet finished.

## About

[This repository](https://github.com/SaschaWillems/HowToVulkan) and the accompanying tutorial demonstrate ways of writing a [Vulkan](https://vulkan.org/) graphics application in 2026. The goal is to leverage modern features to simplify Vulkan usage and, while doing so, create something more than just a basic colored triangle.

Vulkan was released almost 10 years ago, and a lot has changed. Version 1.0 had to make many concessions to support a broad range of GPUs across desktop and mobile. Some of the initial concepts like render passes turned out to be not so optimal, and have been replaced by alternatives. The API matured and new areas like raytracing, video acceleration and machine learning were added. Just as important as the API is the ecosystem, which also changed a lot, giving us new options for writing shaders in languages different than GLSL and tools to help with Vulkan.

And so for this tutorial we will be using [Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html) as a baseline. This gives us access to several features that make Vulkan easier to use while still supporting a wide range of GPUs and platforms. The ones we will be using are:

| Feature | Description |
| - | - |
| [Dynamic rendering](https://www.khronos.org/blog/streamlining-render-passes) | Greatly simplifies render pass setup, one of the most criticized Vulkan areas |
| [Buffer device address](https://docs.vulkan.org/guide/latest/buffer_device_address.html) | Lets us access buffers via pointers instead of going through descriptors |
| [Descriptor indexing](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html) | Simplifies descriptor management, often referred to as "bindless" |
| [Synchronization2](https://docs.vulkan.org/guide/latest/extensions/VK_KHR_synchronization2.html) | Improves synchronization handling, one of the hardest areas of Vulkan |

tl;dr: Doing Vulkan in 2026 can be very different from doing Vulkan in 2016. That's what I hope to show with this.

## Target audience

The tutorial is focused on writing actual Vulkan code and getting things up and running as fast as possible (possibly in an afternoon). It won't explain programming, software architecture, graphics concepts or how Vulkan works (in detail). Instead it'll often contain links to relevant information like the [Vulkan specification](https://docs.vulkan.org/). You should bring at least basic knowledge of C/C++ and realtime graphics concepts.

## Goal

We focus on rasterization, other parts of Vulkan like compute or raytracing are not covered. At the end of this we'll have multiple illuminated and textured 3D objects on screen that can be rotated using the mouse ([screenshot](images/screenshot.png)). Source comes in a single file with a few hundred lines of code, no abstractions, hard to read modern C++ language constructs or object-oriented shenanigans. I believe that being able to follow source code from top to bottom without having to go through multiple layers of abstractions makes it much easier to follow.

## License

Copyright (c) 2025-2026, [Sascha Willems](https://www.saschawillems.de). The contents of this document are licensed under the [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) license. Source code listings and files are licensed under the MIT license.

## Libraries

Vulkan is an explicit low-level API. Writing code for it can be very verbose. To concentrate on the interesting parts we'll be using the following libraries:

* [SFML](https://www.sfml-dev.org/) - Windowing and input (among other things not used in this tutorial). Without a library like this we would have to write a lot of platform specific code. Alternatives are [glfw](https://www.glfw.org/) and [SDL](https://www.libsdl.org/).
* [Volk](https://github.com/zeux/volk) - Meta-loader that simplifies loading of Vulkan functions.
* [VMA](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator) - Simplifies dealing with memory allocations. Removes some of the verbosity around memory management.
* [glm](https://github.com/g-truc/glm) - A mathematics library with support for things like matrices and vectors.
* [tinyobjloader](https://github.com/tinyobjloader/tinyobjloader) - Single file loader for the obj 3D format.
* [KTX-Software](https://github.com/KhronosGroup/KTX-Software) - Khronos KTX GPU texture image file loader.

!!! Tip

	None of these are required to work with Vulkan. But they make working with Vulkan easier and some of them like VMA and Volk are widely used, even in commercial applications.

## Programming language

We'll use C++ 20, mostly for its designated initializers. They help with Vulkan's verbosity and improve code readability. Other than that we won't be using modern C++ features and also work with the C Vulkan headers instead of the [C++](https://github.com/KhronosGroup/Vulkan-Hpp) ones. Aside from personal preferences this is done to make this tutorial as approachable as possible, including people that use other programming languages.

## Shading language

Vulkan consumes shaders in an intermediate format called [SPIR-V](https://www.khronos.org/spirv/). This decouples the API from the actual shading language. Initially only GLSL was supported, but in 2026 there are more and better options. One of those is [Slang](https://github.com/shader-slang), and that's what we'll be using for this tutorial. The language itself is more modern than GLSL and offers some convenient features.

## Vulkan SDK

While it's not required for developing Vulkan applications, the [LunarG Vulkan SDK](https://vulkan.lunarg.com/sdk/home) provides a convenient way to install commonly used libraries and tools, some of which are used in this tutorial. It's therefore recommended to install this. When installing, make sure the GLM, Volk and Vulkan Memory Allocator components are selected (which is true by default).

## Validation layers

Vulkan was designed to minimize driver overhead. While that *can* result in better performance, it also removes many of the safeguards that APIs like OpenGL had and puts that responsibility into your hands. If you misuse Vulkan the driver is free to crash. So even if your app works on one GPU, it doesn't guarantee that it works on others. On the other hand, the Vulkan specification defines valid usages for all functionality. And with the [validation layers](https://github.com/KhronosGroup/Vulkan-ValidationLayers), an easy-to-use tool to check for that exists. 

Validation layers can be enabled in code, but the easier option is to enable the layers via the [Vulkan Configurator GUI](https://vulkan.lunarg.com/doc/view/latest/windows/vkconfig.html) provided by the [Vulkan SDK](#vulkan-sdk). Once they're enabled, any improper use of the API will be logged to the command line window of our application.

!!! Note

	You should always have the validation layers enabled when developing with Vulkan. This makes sure you write spec-compliant code that properly works on other systems.

## Graphics debugger

Another indispensable tool is a graphics debugger. Similar to the CPU debugger available in IDEs like Visual Studio, these help you debug runtime issues on the GPU side of things. A commonly used cross-platform and cross-vendor graphics debugger with Vulkan support is [RenderDoc](https://renderdoc.org/). While using such a debugger isn’t required for this tutorial, it’s invaluable if you want to build upon what you’ve learned and encounter issues while doing so.

## Development environment

Our build system will be [CMake](https://cmake.org/). Similar to my approach to writing code, things will be kept as simple as possible with the added benefit of being able to follow this tutorial with a wide variety of C++ compilers and IDEs.

To create build files for your C++ IDE, run CMake in the source folder of the project like this:

```bash
cmake -B build -G "Visual Studio 17 2022"
```

This will write a Visual Studio 2022 solution file to the `build` folder. As an alternative to the command line, you can use [cmake-gui](https://cmake.org/cmake/help/latest/manual/cmake-gui.1.html). The generator (-G) depends on your IDE, you can find a list of those [here](https://cmake.org/cmake/help/latest/manual/cmake-generators.7.html).

## Source

Now that everything is properly set up we can start digging into the code. The following chapters will walk you through the [main source file](https://github.com/SaschaWillems/HowToVulkan/blob/main/source/main.cpp) from top to bottom. Some of the less interesting boilerplate, like variable declarations, are omitted from this document.

## Instance setup

The first thing we need is a Vulkan instance. It connects the application to Vulkan and as such is the base for everything that follows.

Setting up the instance consists of passing information about your application:

```cpp
VkApplicationInfo appInfo{
	.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
	.pApplicationName = "How to Vulkan",
	.apiVersion = VK_API_VERSION_1_3
};
```

Most important is the `apiVersion`, which tells Vulkan that we want to use Vulkan 1.3. Using a higher API version gives us more features out of the box that otherwise would have to be used via extensions. [Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html) is widely supported and adds a lot of features to the Vulkan core that make it easier to use. `pApplicationName` can be used to identify your application.

!!! Info
	
	A structure member you'll see a lot is `sType`. The driver needs to know what structure type it has to deal with, and with Vulkan being a C-API there is no other way than specifying it via structure member.

The instance also needs to know about the extensions you want to use. As the name implies, these are used to extend the API. As instance creation (and some other things) are platform specific, the instance needs to know what platform specific extensions you want to use. For Windows e.g. you'd use [VK_KHR_win32_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_win32_surface.html) and [VK_KHR_android_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_android_surface.html) for Android and so on for other platforms.

!!! Note

	There are two extension types in Vulkan. Instance and device extensions. The former are mostly global, often platform specific extensions independent of your GPU, the latter are based on your GPU's capabilities.

That would mean we'd have to write platform specific code. **But** with a library like SFML we don't have to do that, instead we ask SFML for the platform specific instance extensions:

```cpp
const std::vector<const char*> instanceExtensions{ sf::Vulkan::getGraphicsRequiredInstanceExtensions() };
```

So no more need to worry about platform specific things. With the application info and the required extensions set up, we can create our instance:

```cpp
VkInstanceCreateInfo instanceCI{
	.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
	.pApplicationInfo = &appInfo,
	.enabledExtensionCount = static_cast<uint32_t>(instanceExtensions.size()),
	.ppEnabledExtensionNames = instanceExtensions.data(),
};
chk(vkCreateInstance(&instanceCI, nullptr, &instance));
```

This is very simple. We pass our application info and both the names and number of instance extensions that SFML gave us (for the platform we're compiling for). Calling [`vkCreateInstance`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateInstance.html) creates our instance.

!!! Tip

	Most Vulkan functions can fail in different ways and return a [`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html) value. We use a small inline function called `chk` to check that return code and in case of an error we exit the application. In a real-world application you should do more sophisticated error handling.

## Queues

In Vulkan, work is not directly submitted to a device but rather to a queue. A queue abstracts access to a piece of hardware (graphics, compute, transfer, video, etc.). They are organized in queue families, with each family describing a set of queues with common functionality. Available queue types differ between GPUs. As we'll only do graphics operations, we need to just find one queue family with graphics support. This is done by checking for the [`VK_QUEUE_GRAPHICS_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkQueueFlagBits.html) flag:

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

!!! Tip

	You'll rarely find GPUs that don't have a queue family that supports graphics. Also most of the time the first queue family supports both graphics and compute (as well as presentation, more on that later). It's still a good practice to check this like we do above, esp. if you add in other queue types like compute.

For our next step we need to reference that queue family using a [`VkDeviceQueueCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkDeviceQueueCreateInfo.html). It is possible to request multiple queues from the same family, but we won't require that. That's why we need to specify priorities in `pQueuePriorities` (in our case just one). With multiple queues from the same family, a driver might use that information to prioritize work:

```cpp
const float qfpriorities{ 1.0f };
VkDeviceQueueCreateInfo queueCI{
	.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
	.queueFamilyIndex = queueFamily,
	.queueCount = 1,
	.pQueuePriorities = &qfpriorities
};
```

## Device setup

Now that we have a connection to the Vulkan library and know what queue family we want to use, we need to get a handle to the GPU. This is called a **device** in Vulkan. Vulkan distinguishes between physical and logical devices. The former presents the actual device (usually the GPU), the latter presents a handle to that device's Vulkan implementation which the application will interact with.

!!! Info
	
	When dealing with Vulkan a commonly used term is implementation. This refers to something that implements the Vulkan API. Usually it's the driver for your GPU, but it also could be a CPU based software implementation. To keep things simple we'll be using the term GPU for the rest of the tutorial.

First we need to get a list of physical devices currently available:

```cpp
uint32_t deviceCount{ 0 };
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr));
std::vector<VkPhysicalDevice> devices(deviceCount);
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data()));
```

!!! Info

	Having to call functions that return some sort of list twice is common in the Vulkan C-API. The first call will return the number of elements, which is then used to properly size the result list. The second call then fills the actual result list.

After the second call to [`vkEnumeratePhysicalDevices`](https://docs.vulkan.org/refpages/latest/refpages/source/vkEnumeratePhysicalDevices.html) we have a list of available Vulkan capable devices. On most systems there will only be one device, so for simplicity we use the first physical device. In a real-world application you could let the user select different devices, e.g. via command line arguments.

One thing that's also part of device creation is requesting features and extensions we want to use. Our instance was created with Vulkan 1.3 as a baseline, which gives us almost all the features we want to use. So we only have to request the [`VK_KHR_swapchain`](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_swapchain.html) extension in order to be able to present something to the screen:

```cpp
const std::vector<const char*> deviceExtensions{ VK_KHR_SWAPCHAIN_EXTENSION_NAME };
```

!!! Tip

	The Vulkan header defines constants for all extensions like `VK_KHR_SWAPCHAIN_EXTENSION_NAME`. You can use these instead of writing their name as a string. This helps to avoid typos in extension names.

Using Vulkan 1.3 as a baseline, we can use the features mentioned [earlier on](#about) without resorting to extensions. When using extension, that would require more code, and checks and fallback paths if an extensions would not be present. With core features, we can instead simply enable them:

```cpp
VkPhysicalDeviceVulkan12Features enabledVk12Features{
	.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
	.descriptorIndexing = true,
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

`descriptorBindingVariableDescriptorCount` and `runtimeDescriptorArray` are related to descriptor indexing, the rest of the names match the actual feature. We also enable [anisotropic filtering](https://docs.vulkan.org/refpages/latest/refpages/source/VkPhysicalDeviceFeatures.html#_members) for better texture filtering.

!!! Info

	Another Vulkan struct member you're going to see often is `pNext`. This can be used to create a linked list of structures that are passed into a function call. The driver then uses the `sType` member of each structure in that list to identify said structure's type.

With everything in place, we can create a logical device with the core features, extensions and the queue families we want to use:

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

We also need a queue to submit our graphics commands to, which we can now request from the device we just created:

```cpp
vkGetDeviceQueue(device, queueFamily, 0, &queue);
```

## Setting up VMA

Vulkan is an explicit API, which also applies to memory management. As noted in the list of libraries we will be using the [Vulkan Memory Allocator (VMA)](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator) to significantly simplify this area.

VMA provides an allocator used to allocate memory from. This needs to be set up for your project once. For that we pass in pointers to some common Vulkan functions, our Vulkan instance and device, we also enable support for buffer device address (`flags`):

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

	VMA also uses [`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html) return codes, we can use the same `chk` function to check VMA's function results.

## Window and surface

To "draw" something in Vulkan (the correct term would be "present an image", more on that later) we need a surface. Most of the time, a surface is taken from a window. Creating both is platform specific, as mentioned in the [instance chapter](#instance-setup). So in theory, this *would* require us to write different code paths for all platform we want to support (Windows, Linux, Android, etc.).

But that's where libraries like SFML come into play. They take care of all the platform specifics for us, so that part becomes dead simple.

!!! Tip

	Libraries like SFML, glfw or SDL also take care of other platform specific functionality like input, audio and networking (to a varying degree).

First we create a window:

```cpp
auto window = sf::RenderWindow(sf::VideoMode({ 1280, 720u }), "How to Vulkan");
```

And then request a Vulkan surface for that window:

```cpp
chk(window.createVulkanSurface(instance, surface));
```

For the following chapter(s) we'll need to know the properties of the surface we just created, we get them via [`vkGetPhysicalDeviceSurfaceCapabilitiesKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceSurfaceCapabilitiesKHR.html) and store them for future reference:

```cpp
VkSurfaceCapabilitiesKHR surfaceCaps{};
chk(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(devices[deviceIndex], surface, &surfaceCaps));
```

## Swapchain

To visually present something to a surface (in our case, the window) we need to create a swapchain. It's basically a series of images, storing color information, that you enqueue to the presentation engine of the operating system. The [`VkSwapchainCreateInfoKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkSwapchainCreateInfoKHR.html) is pretty extensive and requires some explanation.

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
	.queueFamilyIndexCount = queueFamily,
	.preTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR,
	.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
	.presentMode = VK_PRESENT_MODE_FIFO_KHR
};
chk(vkCreateSwapchainKHR(device, &swapchainCI, nullptr, &swapchain));
```

We're using the 4 component color format `VK_FORMAT_B8G8R8A8_SRGB` with a non-linear sRGB [color space](https://docs.vulkan.org/refpages/latest/refpages/source/VkColorSpaceKHR.html) `VK_COLORSPACE_SRGB_NONLINEAR_KHR`. This combination is guaranteed to be available everywhere. Different combinations would require checking for support. `minImageCount` will be the minimum number of images we get from the swapchain. This value varies between GPUs, hence why we use the information we earlier requested from the surface. `presentMode` defines the way in which images are presented to the screen. [`VK_PRESENT_MODE_FIFO_KHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPresentModeKHR.html#) is a v-synced mode and the only mode guaranteed to be available everywhere.

!!! Note

	The swapchain setup shown here is a bare minimum. In a real-world application this part can be quite complicated, as you might have to adjust it based on user settings. One example would be HDR capable devices, where you'd need to use a different image format and color space.

Something special about the swapchain is that its images are not owned by the application, but rather by the swapchain. So instead of explicitly creating these on our own, we request them from the swapchain. This will give us at least as many images as set by `minImageCount`:

```cpp
uint32_t imageCount{ 0 };
vkGetSwapchainImagesKHR(device, swapchain, &imageCount, nullptr);
swapchainImages.resize(imageCount);
vkGetSwapchainImagesKHR(device, swapchain, &imageCount, swapchainImages.data());
swapchainImageViews.resize(imageCount);
```

## Depth attachment

As we're rendering three-dimensional objects, we want to make sure they're properly displayed, no matter from what perspective you look at them, or in which order their triangles are rasterized. That's done via [depth testing](https://docs.vulkan.org/spec/latest/chapters/fragops.html#fragops-depth) and to use that we need to have a depth attachment.

The properties of the depth image are defined in a [`VkImageCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageCreateInfo.html) structure. Some of these are similar to those found at swapchain creation:

```cpp
const VkFormat depthFormat{ VK_FORMAT_D24_UNORM_S8_UINT };
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
!!! Note

	We use a fixed depth format (`VK_FORMAT_D24_UNORM_S8_UINT`). This is a [mandatory format](https://docs.vulkan.org/spec/latest/chapters/formats.html#features-required-format-support), meaning it's supported on every GPU supporting Vulkan. Depending on your needs you could use different formats that e.g. only have depth.

The image is 2D and uses a format with support for depth. We don't need multiple mip levels or Layers. Using optimal tiling with [`VK_IMAGE_TILING_OPTIMAL`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageTiling.html) makes sure the image is stored in a format best suited for the GPU. We also need to state our desired usage cases for the image, which is [`VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageUsageFlagBits.html) as we'll use it as the depth attachment for our render output (more on that later). The initial layout defines the image's content, which we don't have to care about, so we set that to [`VK_IMAGE_LAYOUT_UNDEFINED`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html).

This is also the first time we'll use VMA to allocate something in Vulkan. Memory allocation for buffers and images in Vulkan is verbose yet often very similar. With VMA we can do away with a lot of that. VMA also takes care of selecting the correct memory types and usage flags, something that would otherwise require a lot of code to get proper.

```cpp
VmaAllocationCreateInfo allocCI{
	.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
vmaCreateImage(allocator, &depthImageCI, &allocCI, &depthImage, &depthImageAllocation, nullptr);
```	

One thing that makes VMA so convenient is [`VMA_MEMORY_USAGE_AUTO`](https://gpuopen-librariesandsdks.github.io/VulkanMemoryAllocator/html/choosing_memory_type.html). This usage flag will have VMA select the required usage flags automatically based on the other values you pass in for the allocation and/or buffer create info. There are some cases where you might be better off explicitly stating usage flags, but in most cases the auto flag is the perfect fit. The `VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT` flag tells VMA to create a separate memory allocation for this resource, which is recommended for e.g. large image attachments.

!!! Tip

	We only need a single image, even if we do double buffering in other places. That's because the image is only ever accessed by the GPU and the GPU can only ever write to a single depth image at a time. This differs from resources shared by the CPU and the GPU, but more on that later.

Images in Vulkan are not accessed directly, but rather through [views](https://docs.vulkan.org/spec/latest/chapters/resources.html#VkImageView), a common concept in programming. This adds flexibility and allows different access patterns for the same image.

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

We need a view to the image we just created and we want to access it as a 2D view. The `subresourceRange` specifies the part of the image we want to access via this view. For images with multiple layers or (mip) levels you could do separate image views to any of these and access an image in different ways. The `aspectMask` refers to the aspect of the image that we want to access via the view. This can be color, stencil, or (in our case) the depth part of the image.

With both the image and the image view created, our depth attachment is now ready to be used later on for rendering.

## Loading meshes

From Vulkan's perspective there is no technical difference between drawing a single triangle or a complex mesh with thousands of triangles. Both result in some sort of buffer that the GPU will read data from. The GPU does not care where that data comes from. But from a learning experience it's much better to load an actual 3D object instead of displaying a triangle from hardcoded vertex data. That's our next step.

There are plenty of formats around for storing 3D models. [glTF](https://www.khronos.org/Gltf) for example offers a lot of features and is extensible in a way similar to Vulkan. But we want to keep things simple, so we'll be using the [Wavefront .obj format](https://en.wikipedia.org/wiki/Wavefront_.obj_file) instead. As far as 3D formats go, it won't get more plain than this. And it's supported by many tools like [Blender](https://www.blender.org/).

First we declare a struct for the vertex data we plan to use in our application. That's vertex positions, vertex normals (used for lighting), and texture coordinates. These are colloquially abbreviated as [uv](https://en.wikipedia.org/wiki/UV_mapping):

```cpp
struct Vertex {
	glm::vec3 pos;
	glm::vec3 normal;
	glm::vec2 uv;
};
```

We're using the [tinyobjloader library](https://github.com/tinyobjloader/tinyobjloader) to load .obj files. It does all the parsing and gives us structured access to the data contained in that file:

```cpp
// Mesh data
tinyobj::attrib_t attrib;
std::vector<tinyobj::shape_t> shapes;
std::vector<tinyobj::material_t> materials;
chk(tinyobj::LoadObj(&attrib, &shapes, &materials, nullptr, nullptr, "assets/suzanne.obj"));
```

After a successful call to `LoadObj`, we can access the vertex data stored in the selected .obj file. `attrib` contains a linear array of the vertex data, `shapes` contains indices into that data. `materials` won't be used, we'll do our own shading. 

!!! Warning

	The .obj format is a bit dated and doesn't match modern 3D pipelines in all aspects. One such aspect is indexing of the vertex data. Due to how .obj files are structured we end up with one index per vertex, which limits the effectiveness of indexed rendering. In a real-world application you'd use formats that work well with indexed rendering like glTF.

We'll be using interleaved vertex attributes. Interleaved means, that in memory, for every vertex three floats for the position are followed by three floats for the normal vector (used for lighting), which in turn is followed by two floats for texture coordinates.

To make that work, we need to convert position, normal and texture coordinate values data provided by tinyobj:

```cpp
const VkDeviceSize indexCount{shapes[0].mesh.indices.size()};	
std::vector<Vertex> vertices{};
std::vector<uint16_t> indices{};
// Load vertex and index data
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
	
	The value of the position's and normal's y-axis, and the texture coordinate's v-axis are flipped. This is done to accommodate for Vulkan's coordinate system. Otherwise the model and the texture image would appear upside down.

With the data stored in an interleaved way we can now upload it to the GPU. For that we need to create a buffer that's going to hold the vertex and index data:

```cpp
VkDeviceSize vBufSize{ sizeof(Vertex) * vertices.size() };
VkDeviceSize iBufSize{ sizeof(uint16_t) * indices.size() };
VkBufferCreateInfo bufferCI{
	.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
	.size = vBufSize + iBufSize,
	.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_INDEX_BUFFER_BIT
};
```

Instead of having separate buffers for vertices and indices, we'll put both into the same buffer. Hence why the `size` of the buffer is calculated from the size of both vertices and index vectors. The buffer [`usage`](https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html) bit mask combination of `VK_BUFFER_USAGE_VERTEX_BUFFER_BIT` and `VK_BUFFER_USAGE_INDEX_BUFFER_BIT` signals that intended use case to the driver.

Similar to creating images earlier on we use VMA to allocate the buffer for storing vertex and index data:

```cpp
VmaAllocationCreateInfo bufferAllocCI{
	.flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT | VMA_ALLOCATION_CREATE_MAPPED_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
chk(vmaCreateBuffer(allocator, &bufferCI, &bufferAllocCI, &vBuffer, &vBufferAllocation, nullptr));
```

We again use `VMA_MEMORY_USAGE_AUTO` to have VMA select the correct usage flags for the buffer. The specific `flags` combination of `VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT` and `VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT` used here make sure we get a memory type that's located on the GPU (in VRAM) and accessible by the host. While it's possible to keep vertices and indices in CPU memory, accessing that by the GPU will be a lot slower. Such memory types initially were only available on systems with a unified memory architecture like mobiles or computers with an integrated GPU. But thanks to [(Re)BAR/SAM](https://en.wikipedia.org/wiki/PCI_configuration_space#Resizable_BAR) even dedicated GPUs can now map at least some of their VRAM into host space and make it accessible via the CPU.

!!! Note

	Without this we'd have to create a so-called "staging" buffer on the host, copy data to that buffer and then submit a buffer copy from staging to the GPU side buffer using a command buffer. That would require a lot more code.

The `VMA_ALLOCATION_CREATE_MAPPED_BIT` flag lets us map the buffer, which in turn lets us directly copy data into VRAM:

```cpp
void* bufferPtr{ nullptr };
vmaMapMemory(allocator, vBufferAllocation, &bufferPtr);
memcpy(bufferPtr, vertices.data(), vBufSize);
memcpy(((char*)bufferPtr) + vBufSize, indices.data(), iBufSize);
vmaUnmapMemory(allocator, vBufferAllocation);
```

## CPU and GPU parallelism

In graphics heavy applications, the CPU is mostly used to feed work to the GPU. When OpenGL was invented, computers had one CPU with a single core. But today, even mobile devices have multiple cores and Vulkan gives us more explicit control over how work is distributed across these and the GPU.

This lets us have CPU and GPU work in parallel where possible. So while the GPU is still busy, we can already start creating the next "work package" on the CPU. The naive approach would be having the GPU always wait on the CPU (and vice versa), but that would kill any chance of parallelism.

!!! Tip

	Keeping this in mind will help understand why things like [command buffers](#command-buffers) exist in Vulkan and why we duplicate certain resources.

A prerequisite for that is to multiply resources shared by the CPU and GPU. That way the CPU can start updating resource *n+1* while the GPU is still using resource *n*. That's basically double (or multi) buffering and is often referred to as "frames in flight" in Vulkan.

While in theory we could have many frames in flight, each added frame in flight also adds latency. So usually you have no more than 2 or 3 frames in flight. We define this at the very top of our code:

```cpp
constexpr uint32_t maxFramesInFlight{ 2 };
```

And use it to dimension all resources that are shared by the CPU and GPU:

```cpp
std::array<ShaderDataBuffer, maxFramesInFlight> shaderDataBuffers;
std::array<VkCommandBuffer, maxFramesInFlight> commandBuffers;
```

!!! Note

	The concept of frames in flight only applies to resource shared by CPU and GPU. Resources that are only used by the GPU don't have to be multiplied. This applies to e.g. images.

## Shader data buffers

We also want to pass values to our [shaders](#the-shader) that can change on the CPU side, e.g. from user input. For that we are going to create buffers that can be written by the CPU and read by the GPU. The data in these buffers stays constant (uniform) across all shader invocations for a draw call. This is an important guarantee for the GPU. 

The data we want to pass is stored in a single structure and laid out consecutively, so we can easily copy it over to the matching GPU structure:

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

	It's important to match structure layouts between CPU-side and GPU-side. Depending on the data types and arrangement used, layouts might look the same but will actually be different due to how shading languages align struct members. One way to avoid this, aside from manually aligning or padding structures, is to use Vulkan's [VK_EXT_scalar_block_layout](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_scalar_block_layout.html) or the corresponding Vulkan 1.2 core feature (both are optional).


If we were to use older Vulkan versions we now *would* have to deal with descriptors, a fundamental but partially limiting and hard to manage part of Vulkan. 

But by using Vulkan 1.3's [buffer device address](https://docs.vulkan.org/guide/latest/buffer_device_address.html) feature, we can do away with descriptors (for buffers). Instead of having to access them through descriptors, we can access buffers via their address using pointer syntax in the shader. Not only does that make things easier to understand, it also removes some coupling and requires less code.

As mentioned in [the previous chapter](#cpu-and-gpu-parallelism), we create one shader data buffer per the maximum number of frames in flight. That way we can update one buffer on the CPU while the GPU reads from another one. This ensures we don't run into any read/write hazards where the CPU starts updating values while the GPU is still reading them:

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
	chk(vmaCreateBuffer(allocator, &uBufferCI, &uBufferAllocCI, &shaderDataBuffers[i].buffer, &shaderDataBuffers[i].allocation, nullptr));
	vmaMapMemory(allocator, shaderDataBuffers[i].allocation, &shaderDataBuffers[i].mapped);
```

Creating these buffers is similar to creating the vertex/index buffers for our mesh. The create info structure states that we want to access this buffer via it's device address (`VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT`). The buffer size must (at least) match that of our CPU data structure. We again use VMA to handle the allocation, using the same flags as for the vertex/index buffer to make sure we get a buffer that's accessible by both the CPU and GPU. Once the buffer has been created we map it persistently. Unlike in older APIs, this is perfectly fine in Vulkan and makes it easier to update the buffers later on, as we can just keep a permanent pointer to the buffer (memory).

!!! Tip

	Unlike larger, static buffers, buffers for passing small amounts of data to shaders don't have to be stored in the GPU's VRAM. While we still ask VMA for such a memory type, falling back to CPU-side memory wouldn't be an issue.

```cpp
	VkBufferDeviceAddressInfo uBufferBdaInfo{
		.sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO,
		.buffer = shaderDataBuffers[i].buffer
	};
	shaderDataBuffers[i].deviceAddress = vkGetBufferDeviceAddress(device, &uBufferBdaInfo);
}
```

To be able to access the buffer in our shader, we then get its device address and store it for later access.

## Synchronization objects

Another area where Vulkan is very explicit is [synchronization](https://docs.vulkan.org/spec/latest/chapters/synchronization.html). Other APIs like OpenGL did this implicitly for us. But here, we need to make sure that access to GPU resources is properly guarded to avoid any write/read hazards that could happen by e.g. the CPU starting to write to memory still in use by the GPU. This is somewhat similar to doing multithreading on the CPU but more complicated because we need to make this work between the CPU and GPU, both being very different type of processing units, and also on the GPU itself.

!!! Warning

	Getting synchronization right in Vulkan can be very hard, especially since wrong or missing synchronization might not be visible on all GPUs or in all situations. Sometimes it only shows with low frame rates or on mobile devices. The [validation layers](#validation-layers) include a way to check this with the synchronization validation preset. Make sure to enable it from time to time and check for any hazards reported.

We'll be using different means of synchronization during this tutorial:

* [Fences](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-fences) are used to signal work completion from GPU to CPU. We use them when we need to make sure that a resource used by both GPU and CPU is free to be modified on the CPU.
* [Semaphores](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-semaphores) are used to control access to resources on the GPU-side (only). We use them to ensure proper ordering for things like presentation.
* [Pipeline barriers](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-pipeline-barriers) are used to control resource access within a GPU queue. We use them for layout transitions of images.

Fences and semaphores are objects that we have to create and store, barriers instead are issued as commands and will be discussed later:

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

There aren't a lot of options for creating these objects. Fences will be created in a signalled state by setting the `VK_FENCE_CREATE_SIGNALED_BIT` flag. Otherwise the first wait for such a fence would run into a timeout. We need one fence per [frame-in-flight](#cpu-and-gpu-parallelism) to sync between GPU and CPU. Same for the semaphore used to signal presentation. The no. of semaphores used to signal rendering needs to match that of the swapchain's images. The reason for this is explained later on in [command buffer submission](#submit-command-buffer). 

!!! Tip

	For more complex sync setups, [timeline semaphores](https://www.khronos.org/blog/vulkan-timeline-semaphores) can help reduce the verbosity. They add a semaphore type with a counter value that can be increased and waited on and also can be queried by the CPU to replace fences.

## Command buffers

Unlike older APIs like OpenGL, you can't arbitrarily issue commands to the GPU in Vulkan. Instead we have to record these into [command buffers](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html) and then submit them to a [queue](#queues).

While this makes things a bit more complicated from the application's point-of-view, it helps the driver to optimize things and also enables applications to record command buffers on separate threads. That's another spot where Vulkan allows us to better utilize CPU and GPU resources.

Command buffers have to be allocated from a [command pool](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandPool.html), an object that helps the driver optimize allocations:

```cpp
VkCommandPoolCreateInfo commandPoolCI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
	.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
	.queueFamilyIndex = queueFamily
};
chk(vkCreateCommandPool(device, &commandPoolCI, nullptr, &commandPool));
```

The [`VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandPoolCreateFlagBits.html) flag lets us implicitly reset command buffers when [recording them](#record-command-buffer). We also have to specify the queue family that the command buffers allocated from this pool will be submitted too.

!!! Tip

	It's not uncommon to have multiple command pools in a more complex application. They're cheap to create and if you want to record command buffers from multiple threads you require one such pool per thread.

Command buffers will be recorded on the CPU and executed on the GPU, so we create one per max. [frames in flight](#cpu-and-gpu-parallelism):

```cpp
VkCommandBufferAllocateInfo cbAllocCI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
	.commandPool = commandPool,
	.commandBufferCount = maxFramesInFlight
};
chk(vkAllocateCommandBuffers(device, &cbAllocCI, commandBuffers.data()));
```

A call to [vkAllocateCommandBuffers](https://docs.vulkan.org/refpages/latest/refpages/source/vkAllocateCommandBuffers.html) will allocate `commandBufferCount` command buffers from our just created pool.

## Loading textures

We are now going to load the textures used for rendering the 3D models. In Vulkan, those are images, just like the swapchain or depth image. From a GPU's perspective, images are more complex than buffers, something that's reflected in the verbosity around getting them uploaded to the GPU. 

There are lots of image formats, but we'll go with [KTX](https://www.khronos.org/ktx/), a container format by Khronos. Unlike formats such as JPEG or PNG, it stores images in native GPU formats, meaning we can directly upload them without having to decompress or convert. It also supports GPU specific features like storing mip maps, 3D textures and cubemaps. One tool for creating KTX image files is [PVRTexTool](https://developer.imaginationtech.com/solutions/pvrtextool/).

With the help of that library, Loading such a file from disk is trivial:

```cpp
for (auto i = 0; i < textures.size(); i++) {
	ktxTexture* ktxTexture{ nullptr };
	std::string filename = "assets/suzanne" + std::to_string(i) + ".ktx";
	ktxTexture_CreateFromNamedFile("assets/suzanne.ktx", KTX_TEXTURE_CREATE_LOAD_IMAGE_DATA_BIT, &ktxTexture);
	...
```

!!! Warning

	The textures we load use an 8-bit per channel RGBA format, even though we don't use the alpha channel. You might be tempted to use RGB instead to save memory, but RGB isn't widely supported. If you used such formats in OpenGL the driver often secretly converted them to RGBA. In Vulkan trying to use an unsupported format instead would just fail.

Creating the image (object) is very similar to how we created the [depth attachment](#depth-attachment):

```cpp
VkImageCreateInfo texImgCI{
	.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
	.imageType = VK_IMAGE_TYPE_2D,
	.format = ktxTexture_GetVkFormat(ktxTexture),
	.extent = {.width = ktxTexture->baseWidth, .height = ktxTexture->baseWidth, .depth = 1 },
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

The format is read from the texture using `ktxTexture_GetVkFormat`, width, height and the number of [mip levels](https://docs.vulkan.org/spec/latest/chapters/textures.html#textures-level-of-detail-operation) also come from that. Our desired `usage` combination means that we want to transfer data loaded from disk to this image (`VK_IMAGE_USAGE_TRANSFER_DST_BIT`) and (at a later point) want to sample from it in a shader (`VK_IMAGE_USAGE_SAMPLED_BIT`). We again use `VK_IMAGE_LAYOUT_UNDEFINED` for the initial layout, as that's the only one allowed in this case (`VK_IMAGE_LAYOUT_PREINITIALIZED` e.g. only works with linear tiled images). Once again `vmaCreateImage` is used to create the image, with `VMA_MEMORY_USAGE_AUTO` making sure we get the most fitting memory type (GPU VRAM).

We also create a view through which the image (texture) will be accessed. In our case we want to access the whole image, including all mip levels:

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

With the empty image created it's time to upload data. Unlike buffers, we can't simply memcpy data to an image. That's because [optimal tiling](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageTiling.html) stores texels in a hardware-specific layout and we have no way to convert to that. Instead we have to create an intermediate buffer that we copy the data to, and then issue a command to the GPU that copies this buffer to the image, doing the conversion in turn.

Creating that buffer is very much the same as creating the [shader data buffers](#shader-data-buffers) with some minor differences:

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
chk(vmaCreateBuffer(allocator, &imgSrcBufferCI, &imgSrcAllocCI, &imgSrcBuffer, &imgSrcAllocation, nullptr));
```

This buffer will be used as a temporary source for a buffer-to-image copy, so the only flag we need is [`VK_BUFFER_USAGE_TRANSFER_SRC_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html). The allocation is handled by VMA, once again.

As the buffer was created with the mappable bit, getting the image data into that buffer is again just a matter of a simple `memcpy`:

```cpp
void* imgSrcBufferPtr{ nullptr };
vmaMapMemory(allocator, imgSrcAllocation, &imgSrcBufferPtr);
memcpy(imgSrcBufferPtr, ktxTexture->pData, ktxTexture->dataSize);
```

Next we need to copy the image data from that buffer to the optimal tiled image on the GPU. For that we have to create a command buffer. We'll get into the detail on how they work [later on](#record-command-buffer). We also create a fence that's used to wait for the command buffer to finish execution:

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

We can then start recording the commands required to get image data to its destination:

```cpp
VkCommandBufferBeginInfo cbOneTimeBI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
	.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
};
vkBeginCommandBuffer(cbOneTime, &cbOneTimeBI);
VkImageMemoryBarrier2 barrierTexImage{
	.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
	.srcStageMask = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
	.srcAccessMask = 0,
	.dstStageMask = VK_PIPELINE_STAGE_2_TRANSFER_BIT_KHR,
	.dstAccessMask = VK_ACCESS_2_TRANSFER_WRITE_BIT_KHR,
	.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
	.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
	.image = textures[i].image,
	.subresourceRange = {.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .levelCount = ktxTexture->numLevels, .layerCount = 1 }
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
	.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
	.image = textures[i].image,
	.subresourceRange = {.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .levelCount = ktxTexture->numLevels, .layerCount = 1 }
};
barrierTexInfo.pImageMemoryBarriers = &barrierTexRead;
vkCmdPipelineBarrier2(cbOneTime, &barrierTexInfo);
vkEndCommandBuffer(cbOneTime);
```

It might look a bit overwhelming at first but it's easily explained. Earlier on we learned about optimal tiled images, where texels are stored in a hardware-specific layout for optimal access by the GPU. That [layout](https://docs.vulkan.org/spec/latest/chapters/resources.html#resources-image-layouts) also defines what operations are possible with an image. That's why we need to change said layout depending on what we want to do next with our image. That's done via a pipeline barrier issued by [vkCmdPipelineBarrier2](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdPipelineBarrier2.html). The first one transitions all mip levels of the texture image from the initial undefined layout to a layout that allows us to transfer data to it (`VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`). We then copy over all the mip levels from our temporary buffer to the image using [vkCmdCopyBufferToImage](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdCopyBufferToImage.html). Finally we transition the mip levels from transfer destination to a layout we can read from in our shader (`VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL`).

!!! Tip

	Extensions that would make this easier are [VK_EXT_host_image_copy](https://www.khronos.org/blog/copying-images-on-the-host-in-vulkan), allowing for copying image data directly from the CPU without having to use a command buffer and [VK_KHR_unified_image_layouts](https://www.khronos.org/blog/so-long-image-layouts-simplifying-vulkan-synchronisation), simplifying image layouts. These aren't widely supported yet, but future candidates for making Vulkan easier to use.

Later on we'll sample these textures in our shader, and sampling parameters used there are defined by a sampler object. We want smooth linear filtering, so we enable [anisotropic filter](https://docs.vulkan.org/spec/latest/chapters/textures.html#textures-texel-anisotropic-filtering) to reduce blur and aliasing. We also set the max. LOD to use all mip levels:

```cpp
VkSamplerCreateInfo samplerCI{
	.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
	.magFilter = VK_FILTER_LINEAR,
	.minFilter = VK_FILTER_LINEAR,
	.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR,
	.anisotropyEnable = VK_TRUE,
	.maxAnisotropy = 8.0f, // 8 is a widely supported value for max anisotropy
	.maxLod = (float)ktxTexture->numLevels,
};
chk(vkCreateSampler(device, &samplerCI, nullptr, &textures[i].sampler));
```

At last we clean up and store descriptor related information for that texture to be used later:

```cpp
ktxTexture_Destroy(ktxTexture);
textureDescriptors.push_back({
    .sampler = textures[i].sampler,
    .imageView = textures[i].view,
    .imageLayout = VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL
});
```

Now that we have uploaded the texture images, put them into the correct layout and know how to sample them, we need a way for the GPU to access them in the shader. From the GPU's point of view, images are more complicated than buffers as the GPU needs more information on what they look like an how they're accessed. This is where [descriptors](https://docs.vulkan.org/spec/latest/chapters/descriptorsets.html) are required, handles that represent (describe, hence the name) shader resources. 

In earlier Vulkan versions we would also have to use them for buffers, but as noted in the [shader data buffers](#shader-data-buffers) chapter, buffer device address saves us from doing that. There's no easy to use or widely available equivalent to that for images yet.

And while descriptor handling is still one of the most verbose parts, using [Descriptor indexing](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html), simplifies this significantly respectively makes it easier to scale. With that feature we can go for a "bindless" setup, where all textures are put into one large array and indexed in the [shader](#the-shader) rather than having to create and bind descriptor sets for each and every texture. To demonstrate how this works we'll be loading multiple textures. This approach scales up no matter how many textures you use (within the limits of what the GPU supports).

First we define the interface between our application and the shader in the form of a descriptor set layout:

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

As we're only using descriptors for images, we just have a single binding. The [VkDescriptorSetLayoutBindingFlagsCreateInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorSetLayoutBindingFlagsCreateInfo.html) is used to enable a variable number of descriptors in that binding as part of descriptor indexing and is passed via `pNext`. We combine texture images and samplers (see below), so the binding's type needs to be [`VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER`](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorType.html). There will be as many descriptors in that layout as we have textures loaded and we only need to access this from  the fragment shader, so we set `stageFlags` to `VK_SHADER_STAGE_FRAGMENT_BIT`. A call to [vkCreateDescriptorSetLayout](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateDescriptorSetLayout.html) will then create a descriptor set layout with this configuration. We need this to allocate the descriptor and for defining the shader interface at [pipeline creation](#graphics-pipeline).

!!! Tip

	There are scenarios where you could separate images and samplers, e.g. if you have a lot of images and don't want to waste memory on having samplers for each or if you want to dynamically use different sampling options. In that case you'd use two pool sizes, one for `VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE `and one for `VK_DESCRIPTOR_TYPE_SAMPLER `.

Similar to command buffers, descriptors are allocated from a descriptor pool:

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

The number of descriptor types we want to allocate must be specified here upfront. We need as many descriptors for combined image and samplers as we load textures. We also have to specify how many descriptor sets (**not** descriptors) we want to allocate via `maxSets`. That's one, because with descriptor indexing, we use an array of combined image and samplers. It's also only ever accessed by the GPU, so there is no need to duplicate it per max. frames in flight. Getting pool size right is important, as allocations beyond the requested counts will fail.

Next we allocate the descriptor set from that pool. While the descriptor set layout defines the interface, the descriptor contains the actual descriptor data. The reason that layouts and sets are split is because you can mix layouts and re-use them for different descriptors sets. 

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

Similar to descriptor set layout creation, we have to pass the descriptor indexing setup to the allocation via  [VkDescriptorSetVariableDescriptorCountAllocateInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorSetVariableDescriptorCountAllocateInfo.html) in `pNext`.

The descriptor set allocated by [vkAllocateDescriptorSets](https://docs.vulkan.org/refpages/latest/refpages/source/vkAllocateDescriptorSets.html) is largely uninitialized and needs to be backed with actual data before we can access it in a shader:

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

The [VkDescriptorImageInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorImageInfo.html) refers to an array of descriptors for the textures we loaded above combined with samplers in `pImageInfo`. Calling [vkUpdateDescriptorSets](https://docs.vulkan.org/refpages/latest/refpages/source/vkUpdateDescriptorSets.html) will put that information in the first (and in our case only) binding slot of the descriptor set.

## Loading shaders

As mentioned earlier we'll be using the [Slang language](https://github.com/shader-slang) to write shaders running on the GPU. Vulkan can't directly load shaders written in such a language though (or GLSL or HLSL). It expects them in the SPIR-V intermediate format. For that we need to compile from Slang to SPIR-V first. There are two approaches to do that: Compile offline using Slang's command line compiler or compile at runtime using Slang's library.

We'll go for the latter as that makes updating shaders a bit easier. With offline compilation you'd have to recompile the shaders every time you change them or find a way to have the build system do that for you. With runtime compilation we'll always use the latest shader version when running our code.

To compile Slang shaders, we first create a global Slang session, which is the connection between our application and the Slang library:

```cpp
slang::createGlobalSession(slangGlobalSession.writeRef());
```

Next we create a session to define our compilations scope. We want to compile to SPIR-V, so we need to set the target `format` to `SLANG_SPIRV`. Similar to using a fixed Vulkan version as a baseline we want [SPIR-V 1.4](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_spirv_1_4.html) as our baseline for shaders. This has been added to the core in Vulkan 1.2, so it's guaranteed to be supported in our case. We also change the `defaultMatrixLayoutMode` to a column major layout to match the matrix layout used by Vulkan:

```cpp
auto slangTargets{ std::to_array<slang::TargetDesc>({ {
	.format{SLANG_SPIRV},
	.profile{slangGlobalSession->findProfile("spirv_1_4")}
} }) };
auto slangOptions{ std::to_array<slang::CompilerOptionEntry>({ {
	slang::CompilerOptionName::EmitSpirvDirectly,
	{slang::CompilerOptionValueKind::Int, 1}
} }) };
slang::SessionDesc slangSessionDesc{
	.targets{targets.data()},
	.targetCount{SlangInt(targets.size())},
	.defaultMatrixLayoutMode = SLANG_MATRIX_LAYOUT_COLUMN_MAJOR,
	.compilerOptionEntries{slangTargets.data()},
	.compilerOptionEntryCount{uint32_t(slangTargets.size())}
};
Slang::ComPtr<slang::ISession> slangSession;
slangGlobalSession->createSession(slangSessionDesc, slangSession.writeRef());
```

After a call to `createSession` we can use that session to get the SPIR-V representation of the Slang shader. We first load the textual shader from a file using `loadModuleFromSource` and then use `getTargetCode` to compile all entry points in our shader to SPIR-V:

```cpp
Slang::ComPtr<slang::IModule> slangModule{
    slangSession->loadModuleFromSource("triangle", "assets/shader.slang", nullptr, nullptr)
};
Slang::ComPtr<ISlangBlob> spirv;
slangModule->getTargetCode(0, spirv.writeRef());
```

To then use our shader in our graphics pipeline (see below) we need to create a shader module. These are containers for compiled SPIR-V shaders. To create such a module, we pass the SPIR-V compiled by Slang to [`vkCreateShaderModule`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateShaderModule.html):

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

	The [VK_KHR_maintenance5](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_maintenance5.html) extension, which became core with Vulkan 1.4, deprecated shader modules. It allows direct passing of `VkShaderModuleCreateInfo` to the pipeline's shader stage create info.

## The shader

Although shading languages aren’t as powerful as CPU programming languages, they can still handle complex scenarios. Our shader is intentionally kept simple:

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
    // Calculate view vectors required for lighting
    float4 fragPos = mul(mul(shaderData->view, modelMat), float4(input.Pos.xyz, 1.0));
    output.LightVec = shaderData->lightPos.xyz - fragPos.xyz;
    output.ViewVec = -fragPos.xyz;
    return output;
}

[shader("fragment")]
float4 main(VSOutput input) {
    // Phong lighting
    float3 N = normalize(input.Normal);
    float3 L = normalize(input.LightVec);
    float3 V = normalize(input.ViewVec);
    float3 R = reflect(-L, N);
    float3 diffuse = max(dot(N, L), 0.0025);
    float3 specular = pow(max(dot(R, V), 0.0), 16.0) * 0.75;
    // Sample from texture
    float3 color = textures[input.InstanceIndex].Sample(input.UV).rgb * input.Factor;
    return float4(diffuse * color.rgb + specular, 1.0);
}
```

!!! Tip

	Slang lets us put all shader stages into a single file. That removes the need to duplicate the shader interface or having to put that into shared includes. It also makes it easier to read (and edit) the shader.

It contains two shading stages and starts with defining structures that are used by the different stages. The `ShaderData` structure matches the layout of the shader data structure defined on the [CPU-side](#shader-data-buffers).

First is the vertex shader, marked by the `[shader("vertex")]` attribute. It takes in vertices defined as per `VSInput`, matching the vertex layout from the [graphics pipeline](#graphics-pipeline). The vertex shader will be invoked for every vertex [drawn](#record-command-buffer). As we use buffer device address, we pass and access the UBO as a pointer. As we draw multiple instances of our 3D model and want to use different matrices for every instance, we use the built-in `SV_VulkanInstanceID` system value to index into the model matrices. We also want to highlight the selected model, so if the current instance matches that selection, we pass a different color factor to the fragment shader.

Second is the fragment shader, marked by the `[shader("fragment")]` attribute. First we calculate some basic lighting using the [phong reflection model](https://en.wikipedia.org/wiki/Phong_reflection_model) with values passed from the vertex shader. Then, to demonstrate descriptor indexing, we read from the array of textures (`Sampler2D textures[]`) using the instance index, and finally combine that with the lighting calculation. This is written to the current color attachment.

## Graphics pipeline

Another area where Vulkan strongly differs from OpenGL is state management. OpenGL was a huge state machine, and that state could be changed at any time. This made it hard for drivers to optimize things. Vulkan fundamentally changes that by introducing pipeline state objects. They provide a full set of pipeline state in a "compiled" pipeline object, giving the driver a chance to optimize them. These objects also allow for pipeline object creation in e.g. a separate thread. If you need different pipeline state you have to create a new pipeline state object. 

!!! Note

	There is *some* state in Vulkan that can be dynamic. Mostly basic state like viewport and scissor setup. Them being dynamic is not an issue for drivers. There are several extensions that make additional state dynamic, but we're not going to use them here.

Vulkan supports [pipeline types](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineBindPoint.html) specific to use-cases like graphics, compute, raytracing. As such, setting up a pipeline depends what we want to achieve. In our case, that's graphics (aka [rasterization](https://en.wikipedia.org/wiki/Rasterisation)) so we'll be creating a graphics pipeline.

First we create a pipeline layout. This defines the interface between the pipeline and our shaders. Pipeline layouts are separate objects as you can mix and match them for use with other pipelines:

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

The [`pushConstantRange`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPushConstantRange.html) defines a range of values that we can directly push to the shader without having to go through a buffer. We use these to pass a pointer to the shader data buffer buffer (more on that later). The descriptor set layouts (`pSetLayouts`) define the interface to the shader resources. In our case that's only one layout for passing the texture image descriptors. The call to [`vkCreatePipelineLayout`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineLayoutCreateInfo.html) will create the pipeline layout we can then use for our pipeline.

Another part of our interface between the pipeline and the shader is the layout of the vertex data. In the [mesh loading chapter](#loading-meshes) we defined a basic vertex structure that we now need to specify in Vulkan terms. We use a single vertex buffer, so we require one [vertex binding point](https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputBindingDescription.html). The `stride` matches the size of our vertex structure as our vertices are stored directly adjacent in memory. The `inputRate` is per-vertex, meaning that the data pointer advances for every vertex read:

```cpp
VkVertexInputBindingDescription vertexBinding{
	 .binding = 0,
	 .stride = sizeof(Vertex),
	 .inputRate = VK_VERTEX_INPUT_RATE_VERTEX
};
```

Next we specify how [vertex attributes](https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputAttributeDescription.html) for position, normals and texture coordinates are laid out in memory. This exactly matches our CPU-side vertex structure:

```cpp
std::vector<VkVertexInputAttributeDescription> vertexAttributes{
	{ .location = 0, .binding = 0, .format = VK_FORMAT_R32G32B32_SFLOAT },
	{ .location = 1, .binding = 0, .format = VK_FORMAT_R32G32B32_SFLOAT, .offset = offsetof(Vertex, normal) },
	{ .location = 2, .binding = 0, .format = VK_FORMAT_R32G32_SFLOAT, .offset = offsetof(Vertex, uv) },
};
```
!!! Tip

	Another option for accessing vertices in the shader is buffer device address. That way we would skip the traditional vertex attributes and manually fetch them in the shader using pointers. That's called "vertex pulling". On some devices that can be slower though, so we stick with the traditional way.

Now we start filling in the many `VkPipeline*CreateInfo` structures required to create a pipeline. We won't explain all of these in detail, you can read up on them in the [spec](https://docs.vulkan.org/refpages/latest/refpages/source/VkGraphicsPipelineCreateInfo.html). They're all kinda similar, and describe a particular part of the pipeline.

First up is the pipeline state for the [vertex input](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineVertexInputStateCreateInfo.html) we just defined above:

```cpp
VkPipelineVertexInputStateCreateInfo vertexInputState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
	.vertexBindingDescriptionCount = 1,
	.pVertexBindingDescriptions = &vertexBinding,
	.vertexAttributeDescriptionCount = static_cast<uint32_t>(vertexAttributes.size()),
	.pVertexAttributeDescriptions = vertexAttributes.data(),
};
```

Another structure directly connected to our vertex data is the [input assembly state](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineInputAssemblyStateCreateInfo.html). It defines how [primitives](https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html) are assembled. We want to render a list of separate triangles, so we use [`VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html):

```cpp
VkPipelineInputAssemblyStateCreateInfo inputAssemblyState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
	.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
};
```

An important part of any pipeline are the [shaders](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineShaderStageCreateInfo.html) we want to use and the pipeline stages they map to. Having only a single set of shaders is the reason why we only need a single pipeline. Thanks to Slang we get all stages in a single shader module:

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

	If you'd wanted to use different shaders (or shader combinations), you'd have to create multiple pipelines. The [VK_EXT_shader_objects](https://www.khronos.org/blog/you-can-use-vulkan-without-pipelines-today) makes those shader stages into separate objects and adds more flexibility to this part of the API.

Next we configure the [viewport state](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineViewportStateCreateInfo.html). We use one viewport and one scissor, and we also want them to be dynamic state so we don't have to recreate the pipeline if any of those changes, e.g. when resizing the window. It's one of the few dynamic states that have been there since Vulkan 1.0:

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

As we want to use [depth buffering](#depth-attachment), we configure the [depth/stencil state](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineDepthStencilStateCreateInfo.html) to enable both depth tests and writes and set the compare operation so that fragments closer to the viewer are passing depth tests:

```cpp
VkPipelineDepthStencilStateCreateInfo depthStencilState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
	.depthTestEnable = VK_TRUE,
	.depthWriteEnable = VK_TRUE,
	.depthCompareOp = VK_COMPARE_OP_LESS_OR_EQUAL
};
```

The following state tells the pipeline that we want to use dynamic rendering instead of the cumbersome render pass objects. Unlike render passes, setting this up is fairly trivial and also removes a tight coupling between the pipeline and a render pass. For dynamic rendering we just have to specify the number and formats of the attachments we plan to use (later on):

```cpp
VkPipelineRenderingCreateInfo renderingCI{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO,
	.colorAttachmentCount = 1,
	.pColorAttachmentFormats = &imageFormat,
	.depthAttachmentFormat = depthFormat
};
```

!!! Note

	As this functionality was added at a later point in Vulkan's life, there is no dedicated member for it in the pipeline create info. We instead pass this to `pNext` (see below)

We don't make use of the following state, but they must be specified and also need to have some sane default values. So we set [blending](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineColorBlendStateCreateInfo.html), [rasterization](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineRasterizationStateCreateInfo.html) and [multisampling](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineMultisampleStateCreateInfo.html) to default values:

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

With all relevant pipeline state create structures properly set up, we wire them up to finally create our graphics pipeline:

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

After a successful call to [`vkCreateGraphicsPipelines`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateGraphicsPipelines.html), our graphics pipeline is ready to be used for rendering.

## Render loop

Getting to this point took quite an effort but we're now ready to actually "draw" something to the screen. Like so much before, this is both explicit and indirect in Vulkan. Getting something displayed on screen nowadays is a complex matter compared to how early computer graphics worked. Esp. with an API that has to support so many different platforms and devices.

This brings us to the render loop, in which we'll take user-input, render our scene, update shader values and make sure all of this is properly synchronized between CPU and GPU and on the GPU itself. It's another area that *would* require platform-specific handling. But again SFML will do away with that and simplify the actual loop:

```cpp
sf::Clock clock;
while (window.isOpen()) {
	// Wait on fence
	// Acquire next image
	// Update shader data
	// Record command buffer
	// Submit command buffer
	// Present image
	// Poll events
}
```

The loop will be executed as long as the window stays open. SFML also gives us a precise [clock](https://www.sfml-dev.org/documentation/3.0.2/classsf_1_1Clock.html) that we can use to measure elapsed time for framerate-independent calculations like rotations.

There's a lot happening inside the loop, so we'll look at each part separately.

### Wait on fence

As discussed in [CPU and GPU parallelism](#cpu-and-gpu-parallelism), one area where we can overlap CPU and GPU work is command buffer recording. We want to have the CPU start recording the next command buffer while the GPU is still working on the previous one.

To do that, we wait for fence of the last frame the GPU has worked on to finish execution:

```cpp
chk(vkWaitForFences(device, 1, &fences[frameIndex], true, UINT64_MAX));
chk(vkResetFences(device, 1, &fences[frameIndex]));
```

The call to [vkWaitForFences](https://docs.vulkan.org/refpages/latest/refpages/source/vkWaitForFences.html) will wait on the CPU until the GPU has signalled it has finished all work submitted with that fence. The max. timeout for this wait is set to `UINT64_MAX`. That might sound like much, but that's in nanoseconds, so actually quite a small period. As the fence is still in signaled state, we also need to [reset](https://docs.vulkan.org/refpages/latest/refpages/source/vkResetFences.html) for the next submission.


### Acquire next image

As we don't have direct control over the [swapchain images](#swapchain), we need to "ask" (acquire) the swapchain for the next index to be used in this frame:

```cpp
vkAcquireNextImageKHR(device, swapchain, UINT64_MAX, presentSemaphores[frameIndex], VK_NULL_HANDLE, &imageIndex);
```

It's important to use the image index returned by [vkAcquireNextImageKHR](https://docs.vulkan.org/refpages/latest/refpages/source/vkAcquireNextImageKHR.html) to access the swapchain images. That's because there is no guarantee that images are acquired in consecutive order. That's one of the reasons we have two indices.

We also pass a [semaphore](#synchronization-objects) to this function which will be used later on at command buffer submission.

### Update shader data

We want the next frame to use up-to-date user inputs. This is safe to do now after waiting for the fence. For that we update matrices from current data using glm:

```cpp
shaderData.projection = glm::perspective(glm::radians(45.0f), (float)window.getSize().x / (float)window.getSize().y, 0.1f, 32.0f);
shaderData.view = glm::translate(glm::mat4(1.0f), camPos);
for (auto i = 0; i < 3; i++) {
	auto instancePos = glm::vec3((float)(i - 1) * 3.0f, 0.0f, 0.0f);
	shaderData.model[i] = glm::translate(glm::mat4(1.0f), instancePos) * glm::mat4_cast(glm::quat(objectRotations[i]));
}
```

A simple `memcpy` to the shader data buffer's persistently mapped pointer is sufficient to make this available to the GPU (and with that our shader):

```cpp
memcpy(shaderDataBuffers[frameIndex].mapped, &mvp, sizeof(ShaderData));
```

This works because the [shader data buffers](#shader-data-buffers) are stored in a memory type accessible by both the CPU (for writing) and the GPU (for reading). With the preceding fence synchronization we also made sure that the CPU won't start writing to that shader data buffer before the GPU has finished reading from it.

### Record command buffer

Now we can finally start recording actual GPU work items. A lot of the things we need for that have been discussed earlier, so even though this will be a lot of code, it should be easy to follow. As mentioned in [command buffers](#command-buffers), commands are not directly issued to the GPU in Vulkan but rather recorded to command buffers. That's exactly what we are going to do: record the commands for a single render frame.

You might be tempted to pre-record command buffers and reuse them until something changes that would require re-recording. This makes things unnecessarily complicated however, as you'd have to implement update logic that works with CPU/GPU parallelism. And since recording command buffers is relatively fast and can be offloaded to other CPU threads if needed, recording them every frame is perfectly fine.

!!! Note

	Commands that are recorded into a command buffer start with `vkCmd`. They are not directly executed, but only when the command buffer is submitted to a queue (GPU timeline). A common mistake for beginners is to mix those commands with commands that are instantly executed on the CPU timeline. It's important to remember that these two different timelines exist.

Command buffers have a [lifecycle](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html#commandbuffers-lifecycle) that we have to adhere to. For example we can't record commands to it while it's in the executable state. This is also checked by [validation layers](#validation-layers) that would let us know if we misused things.

First we need to move the command buffer into the initial state. That's done by [resetting it](https://docs.vulkan.org/refpages/latest/refpages/source/vkResetCommandBuffer.html) and is safe to do now as we have waited on the fence earlier on to make sure it's no longer in the pending state:

```cpp
auto cb = commandBuffers[frameIndex];
vkResetCommandBuffer(cb, 0);
```

Once reset, we can start recording the command buffer:

```cpp
VkCommandBufferBeginInfo cbBI {
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
	.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
};
vkBeginCommandBuffer(cb, &cbBI);
```

The [`VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandBufferUsageFlagBits.html) flag affects how lifecycle moves to invalid state after execution and can be used as an optimization hint by drivers. After calling [vkBeginCommandBuffer](https://docs.vulkan.org/refpages/latest/refpages/source/vkBeginCommandBuffer.html), which moves the command buffer into recording state, we can start recording the actual commands.

During rendering, color information will be written to the current [swapchain image](#swapchain), depth information will be written to the [depth image](#depth-attachment). As we learned in [loading textures](#loading-textures), optimal tiled images need to be in the correct layout for their indented use case. As such, the first step is to issue layout transitions for both of them:

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

Not only do [image memory barriers](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-dependencies) transition layouts, they also make sure that this happens at the right [pipeline stage](https://docs.vulkan.org/spec/latest/chapters/pipelines.html#pipelines-block-diagram), enforcing ordering inside a command buffer. Similar to other synchronization primitives we used, these are necessary to make sure the GPU e.g. doesn't start writing to an image in one pipeline stage while a previous pipeline stage is still reading from it. They also make writes visible to following stages. The `srcStageMask` is the pipeline stage(s) to wait on, `srcAccessMask` and defines writes to be made available. `dstStageMask` and `dstAccessMask` define where and what writes to be made visible.

!!! Note

	Available and visible might sound like the same thing, but they aren't. That's due to how CPU/GPUs work and how they interact with caches. Available means data is ready for future memory operations (e.g. cache flushes). Visible means that data is actually visible to reads from the consuming stages.

The *first barrier* transitions the current swapchain image *to* a [layout](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html) (`newLayout`) so that we can use it as a color attachment for rendering. Similarly the *second barrier* transitions the depth image *to* a layout so that we can use it as a depth attachment for rendering. Both transition *from* and undefined layout (`oldLayout`). That's because we don't need the previous content of any of these images.

!!! Tip

	The `VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL` layout is a core feature of Vulkan 1.3 that combines all types of attachment layouts into a single one. This simplifies image barriers.

A call to [vkCmdPipelineBarrier2](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdPipelineBarrier2.html) will then insert those two barriers into the current command buffer.

With the attachments in the correct layout, it's time to define how we are going to use them. As noted early on, we'll use [Dynamic rendering](https://www.khronos.org/blog/streamlining-render-passes) for that, instead of the complicated and cumbersome render pass objects from Vulkan 1.0.

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

We set up one [VkRenderingAttachmentInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkRenderingAttachmentInfo.html) for the swapchain image used as the color attachment and the depth image used as the depth attachment. Both will be cleared to their respective `clearValue` at the start of a render pass with `loadOp` set to `VK_ATTACHMENT_LOAD_OP_CLEAR`. `storeOp` for the color attachment is configured to keep its contents, as we still need them to be presented to the screen. We don't need the depth information once we're done rendering, so we literally don't care what happens with its contents after the render pass. Layouts for both must match what we transitioned them earlier on.

Calling [vkCmdBeginRendering](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdBeginRendering.html) will then start our dynamic render pass instance with above attachment configuration:

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

Inside this render pass instance we can finally start recording GPU commands. Remember that these aren't issued to the GPU just yet, but are only recorded into the current command buffer.

We start by setting up the [viewport](https://docs.vulkan.org/spec/latest/chapters/vertexpostproc.html#vertexpostproc-viewport) to define our rendering area. We always want this to be the whole window. Same for the [scissor](https://docs.vulkan.org/spec/latest/chapters/fragops.html#fragops-scissor) area. Both are part of the dynamic state we enabled at [pipeline creation](#graphics-pipeline), so we can adjust them inside the command buffer instead of having to recreate the graphics pipeline on each window resize:

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

Next up is binding the resources involved in rendering our 3D objects. The [graphics pipeline](#graphics-pipeline), that also includes our vertex and fragment shaders, as well as the descriptor set for the array of our [texture images](#loading-textures) and the vertex and index buffers of our [3D mesh](#loading-meshes):

```cpp
vkCmdBindPipeline(cb, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);
VkDeviceSize vOffset{ 0 };
vkCmdBindDescriptorSets(cb, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &descriptorSetTex, 0, nullptr);
vkCmdBindVertexBuffers(cb, 0, 1, &vBuffer, &vOffset);
vkCmdBindIndexBuffer(cb, vBuffer, vBufSize, VK_INDEX_TYPE_UINT16);
```

We also want to access data in the [shader data buffer](#shader-data-buffer). We opted for using buffer device address instead of going through descriptors, so instead we pass the address of the current frame's shader data buffer via a push constant to the shaders:

```cpp
vkCmdPushConstants(cb, pipelineLayout, VK_SHADER_STAGE_VERTEX_BIT, 0, sizeof(VkDeviceAddress), &shaderDataBuffers[frameIndex].deviceAddress);
```

!!! Note

	These `vkCmd*` calls (and many others) set the current command buffer state. That means they persist across multiple draw calls inside this command buffer. So if you e.g. wanted to issue a second draw call with the same pipeline but a different descriptor sets you'd only have to call `vkCmdBindDescriptorSets` with another set, while keeping the rest of the state.

And with that we are *finally* ready to issue an actual draw command. With all the work we did up to this point, that's just a single command:

```cpp
vkCmdDrawIndexed(cb, indexCount, 3, 0, 0, 0);
```

This call to [vkCmdDrawIndexed](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdDrawIndexed.html) will draw indexCount / 3 triangles from the currently bound index and vertex buffer. We also want to draw multiple instances of our 3D mesh, so we set the instance count (third argument) to 3, which we use in the [vertex shader](#the-shader) to index into the [model matrices](#shader-data-buffers).

We now [finish](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdEndRendering.html) the current render pass:

```cpp
vkCmdEndRendering(cb);
```

And transition the swapchain image that we just used as an attachment (to output color values) to a layout required for [presentation](#present-image):

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

We don't need a barrier for the depth attachment, as we don't use that outside of this render pass.

At last we [end recording](https://docs.vulkan.org/refpages/latest/refpages/source/vkEndCommandBuffer.html) the command buffer: 

```cpp
vkEndCommandBuffer(cb);
``` 

This moves it to the [executable state](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html#commandbuffers-lifecycle). That's a requirement for the next step.

### Submit command buffer

In order to execute the commands we just recorded we need to submit the command buffer to a matching queue. In a real-world application it's not uncommon to have multiple queues of different types and also more complex submission patterns. But we only use graphics commands (no compute or ray tracing) and as such also only have a single graphics queue to which we submit our current frame's command buffer:

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

The [`VkSubmitInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkSubmitInfo.html) structure needs some explanation, esp. in regards to synchronization. Earlier on we learned about the [synchronization primitives](#synchronization-objects) that we need to properly synchronize work between CPU and GPU and the GPU itself. And this is where it all comes together.

The semaphore in `pWaitSemaphores` makes sure the submitted command buffer(s) won't start execution before the presentation of the current frame has finished. The pipeline stage in `pWaitDstStageMask` will make that wait happen at the color attachment output stage of the pipeline, so (in theory) the GPU might already start doing work on parts of the pipeline that come before this, e.g. fetching vertices. The signal semaphore in `pSignalSemaphores` on the other hand is a semaphore that's signalled by the GPU once command buffer execution has completed. This combination ensures that no read/write hazards occur that would have the GPU read from or write to resources still in use.

Notice the distinction between using `frameIndex` for the present semaphore and `imageIndex` for the render semaphore. This is because `vkQueuePresentKHR` (see below) has no way to signal without a certain extension (not yet available everywhere). To work around this we decouple the two semaphore types and use one present semaphore per swapchain image instead. An in-depth explanation for this can be found in the [Vulkan Guide](https://docs.vulkan.org/guide/latest/swapchain_semaphore_reuse.html).

!!! Warning

	Submissions can have multiple wait and signal semaphores and wait stages. In a more complex application (than ours) which might mix graphics with compute, it's important to keep synchronization scope as narrow as possible to allow for the GPU to overlap work. This is one of the hardest parts to get right in Vulkan. Errors can be detected with the [validation layers](#validation-layers), performance can be checked with vendor-specific graphics profilers.

Once work has been submitted, we can calculate the frame index for the next render loop iteration:

```cpp
frameIndex = (frameIndex + 1) % maxFramesInFlight;
```

### Present image

The final step to get our rendering results to the screen is presenting the current swapchain image we used as the color attachment:

```cpp
VkPresentInfoKHR presentInfo{
	.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
	.waitSemaphoreCount = 1,
	.pWaitSemaphores = &renderSemaphores[imageIndex],
	.swapchainCount = 1,
	.pSwapchains = &swapchain,
	.pImageIndices = &imageIndex
};
chk(vkQueuePresentKHR(queue, &presentInfo));
```

Calling [vkQueuePresentKHR](https://docs.vulkan.org/refpages/latest/refpages/source/vkQueuePresentKHR.html) will enqueue the image for presentation after waiting for the render semaphore. That guarantees the image won't be presented until our rendering commands have finished. 

### Poll events

Last but not least, we work through the event queue of the operating system. This is done in an additional loop (inside the render loop) where we call SFML's `pollEvent` until all events have been popped from the queue. We only handle event types we're interested in:

```cpp
while (const std::optional event = window.pollEvent()) {

	// Exit loop if window is about to close
	if (event->is<sf::Event::Closed>()) {
		window.close();
	}

	// Rotate with mouse drag
	if (const auto* mouseMoved = event->getIf<sf::Event::MouseMoved>()) {
		if (sf::Mouse::isButtonPressed(sf::Mouse::Button::Left)) {
			auto delta = lastMousePos - mouseMoved->position;
			objectRotations[shaderData.selected].x += (float)delta.y * 0.0005f * (float)elapsed.asMilliseconds();
			objectRotations[shaderData.selected].y -= (float)delta.x * 0.0005f * (float)elapsed.asMilliseconds();
		}
		lastMousePos = mouseMoved->position;
	}

	// Zooming with the mouse wheel
	if (const auto* mouseWheelScrolled = event->getIf<sf::Event::MouseWheelScrolled>()) {
		camPos.z += (float)mouseWheelScrolled->delta * 0.025f * (float)elapsed.asMilliseconds();
	}

	// Select active model instance
	if (const auto* keyPressed = event->getIf<sf::Event::KeyPressed>()) {
		if (keyPressed->code == sf::Keyboard::Key::Add) {
			shaderData.selected = (shaderData.selected < 2) ? shaderData.selected + 1 : 0;
		}
		if (keyPressed->code == sf::Keyboard::Key::Subtract) {
			shaderData.selected = (shaderData.selected > 0) ? shaderData.selected - 1 : 2;
		}
	}	

	// Window resize
	if (const auto* resized = event->getIf<sf::Event::Resized>()) {
		...
	}
}
```

We want to have some interactivity in our application. For that we calculate rotation for the currently selected model instance based on mouse movement when the left button is down in the `MouseMoved` event. And similar with the mousewheel in `MouseWheelScrolled` to allow zooming the camera in and out. The `keyPressed` event lets us toggle between the model instances.

The `Closed` event is called when our application is to be closed, no matter how. Calling `close` on our SFML window will exit the outer render loop (which checks if the window is open) and jumps to the [clean up](#cleaning-up) part of the code.

Although it's optional, and something games often don't implement, we also handle resizing triggered by the `Resized` event. This require us to recreate some Vulkan objects:

```cpp
if (const auto* resized = event->getIf<sf::Event::Resized>()) {
	vkDeviceWaitIdle(device);
	swapchainCI.oldSwapchain = swapchain;
	swapchainCI.imageExtent = { .width = static_cast<uint32_t>(resized->size.x), .height = static_cast<uint32_t>(resized->size.y) };
	chk(vkCreateSwapchainKHR(device, &swapchainCI, nullptr, &swapchain));
	for (auto i = 0; i < imageCount; i++) {
		vkDestroyImageView(device, swapchainImageViews[i], nullptr);
	}
	vkGetSwapchainImagesKHR(device, swapchain, &imageCount, nullptr);
	swapchainImages.resize(imageCount);
	vkGetSwapchainImagesKHR(device, swapchain, &imageCount, swapchainImages.data());
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

This looks intimidating at first, but it's mostly code we already used earlier on to create the swapchain and the depth image. Before we can recreate these, we call [vkDeviceWaitIdle](https://docs.vulkan.org/refpages/latest/refpages/source/vkDeviceWaitIdle.html) to wait until the GPU has completed all outstanding operations. This makes sure that none of those objects are still in use by the GPU.

An important difference is setting the `oldSwapchain` member of the swapchain create info. This is necessary during recreation to allow the application to continue presenting any already acquired image. Remember we don't have control over those, as they're owned by the swapchain (and the operating system). Other than that it's a simple matter of destroying existing objects (`vkDestroy*`) and creating them a new just like we did earlier on albeit with the new size of the window.

## Cleaning up

Destroying Vulkan resources is just as explicit as creating them. In theory you could exit the application without doing that and have the operating system clean up for you instead. But properly cleaning up after you is common sense and so we do that. We once again call vkDeviceWaitIdle to make sure none of the GPU resources we want to destroy are still in use. Once that call has successfully finished, we can start cleaning up all the Vulkan GPU objects we created in our application:

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

Ordering of commands only matters for the VMA allocator, device and instance. These should only be destroyed after all objects created from them. The instance should be deleted last, that way we'll be notified by the validation layers (when enabled) of every object we forgot to properly delete. One resource you don't have to explicitly destroy are the command buffers. Calling [vkDestroyCommandPool](https://docs.vulkan.org/refpages/latest/refpages/source/vkDestroyCommandPool.html) will implicitly free all command buffers allocated from that pool.

## Closing words

By now, you should have a basic understanding of how to create a Vulkan application that performs rasterization and leverages recent API versions and features. Vulkan remains a relatively verbose API, which is inherent to its explicit, low-level design. But though we still need a lot of code to get something up and running in Vulkan, it's easier to understand and more flexible, making it a solid foundation for more complex applications.

Looking at the broader picture, Vulkan in 2026 supports a wider range of use cases than ever. In addition to rasterization and compute, it also offers functionality for hardware-accelerated raytracing, video encoding and decoding, machine learning, and safety-critical areas.

If you're looking for further resources, check the [Vulkan Docs Site](https://docs.vulkan.org/). It combines multiple Vulkan documentation resources like the spec, a tutorial and samples into a convenient single site.
