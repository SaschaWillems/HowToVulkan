<!--
Copyright (c) 2025-2026, Sascha Willems
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# 2026년의 Vulkan 입문 가이드

!!! Info

	마지막 업데이트: 2026-02-21: VMA를 통한 영구 버퍼 매핑


## 소개

[이 저장소](https://github.com/SaschaWillems/HowToVulkan)와 동반 튜토리얼은 2026년에 [Vulkan](https://vulkan.org/) 그래픽 애플리케이션을 작성하는 방법을 보여줍니다. 목표는 최신 기능을 활용하여 Vulkan 사용을 단순화하고, 그 과정에서 기본적인 색상 삼각형 이상의 것을 만드는 것입니다.

Vulkan이 출시된 지 거의 10년이 되었고, 많은 것이 변했습니다. 버전 1.0은 데스크톱과 모바일 전반에 걸친 광범위한 GPU를 지원하기 위해 많은 양보를 해야 했습니다. 렌더 패스와 같은 초기 개념은 최적이 아닌 것으로 판명되었고, 대안으로 대체되었습니다. API는 성숙해졌고 레이 트레이싱, 비디오 가속 및 기계 학습과 같은 새로운 영역이 추가되었습니다. API만큼 중요한 것이 생태계이며, 이 또한 많이 변하여 GLSL 이외의 언어로 셰이더를 작성하고 Vulkan을 돕는 도구를 사용할 수 있는 새로운 옵션을 제공합니다.

따라서 이 튜토리얼에서는 [Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html)을 기준선으로 사용합니다. 이를 통해 광범위한 GPU와 플랫폼을 계속 지원하면서 Vulkan을 더 쉽게 사용할 수 있는 여러 기능에 액세스할 수 있습니다. 우리가 사용할 기능은 다음과 같습니다:

* [동적 렌더링](https://www.khronos.org/blog/streamlining-render-passes) - 렌더 패스 설정을 크게 단순화, Vulkan에서 가장 비판받은 영역 중 하나
* [버퍼 디바이스 주소](https://docs.vulkan.org/guide/latest/buffer_device_address.html) - 디스크립터를 통하지 않고 포인터를 통해 버퍼에 액세스 가능
* [디스크립터 인덱싱](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html) - 디스크립터 관리를 단순화, 흔히 "바인드리스"(bindless)라고 함
* [동기화2](https://docs.vulkan.org/guide/latest/extensions/VK_KHR_synchronization2.html) - 동기화 처리를 개선, Vulkan에서 가장 어려운 영역 중 하나

요약하자면: 2026년에 Vulkan을 사용하는 것은 2016년에 Vulkan을 사용하는 것과 매우 다를 수 있습니다. 이것이 이 튜토리얼을 통해 보여주고자 하는 것입니다.

!!! Tip

	최소 Vulkan 1.3을 지원하는 장치 목록은 [여기](https://vulkan.gpuinfo.org/listdevices.php?apiversion=1.3)에서 찾을 수 있습니다. 


## 대상 독자

이 튜토리얼은 실제 Vulkan 코드를 작성하고 가능한 한 빨리(오후에) 실행되도록 하는 데 초점을 맞춥니다. 프로그래밍, 소프트웨어 아키텍처, 그래픽 개념 또는 Vulkan의 작동 방식(상세)에 대해서는 설명하지 않습니다. 대신 [Vulkan 사양](https://docs.vulkan.org/)과 같은 관련 정보에 대한 링크를 자주 포함합니다. C/C++와 실시간 그래픽 개념에 대한 기본적인 지식이 있어야 합니다.

## 목표

우리는 래스터라이제이션에 초점을 맞추고, Vulkan의 다른 부분인 계산이나 레이 트레이싱은 다루지 않습니다. 이 튜토리얼이 끝나면 마우스로 회전할 수 있는 조명과 텍스처가 적용된 여러 3D 개체를 화면에 표시합니다([스크린샷](images/screenshot.png)). 소스 코드는 단일 파일에 있으며, 수백 줄의 코드로 구성되어 있고, 추상화, 읽기 어려운 현대 C++ 언어 기능이나 객체 지향적 트릭이 없습니다. 여러 추상화 계층을 통과하지 않고 소스 코드를 위에서 아래까지 따라갈 수 있다면 훨씬 이해하기 쉽다고 믿습니다.

## 라이선스

저작권 (c) 2025-2026, [Sascha Willems](https://www.saschawillems.de). 이 문서의 내용은 [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) 라이선스하에 라이선스됩니다. 소스 코드 목록과 파일은 MIT 라이선스하에 라이선스됩니다.

## 라이브러리

Vulkan은 명시적인 저수준 API입니다. 이를 위한 코드를 작성하는 것은 매우 장황할 수 있습니다. 흥미로운 부분에 집중하기 위해 다음 라이브러리를 사용합니다:

* [SDL](https://www.libsdl.org/) - 윈도우 및 입력(및 이 튜토리얼에서 사용되지 않는 기타 기능). 이러한 라이브러리가 없다면 많은 플랫폼 특정 코드를 작성해야 합니다. 대안으로는 [GLFW](https://www.glfw.org/)와 [SFML](https://www.sfml-dev.org/)이 있습니다. 이 중 SDL이 가장 광범위한 플랫폼 지원을 제공합니다
* [Volk](https://github.com/zeux/volk) - Vulkan 함수 로드를 단순화하는 메타 로더
* [VMA](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator) - 메모리 할당 처리를 단순화합니다. 메모리 관리 주변의 장황함을 줄입니다
* [glm](https://github.com/g-truc/glm) - 행렬 및 벡터 등을 지원하는 수학 라이브러리
* [tinyobjloader](https://github.com/tinyobjloader/tinyobjloader) - obj 3D 형식의 단일 헤더 로더
* [KTX-Software](https://github.com/KhronosGroup/KTX-Software) - Khronos KTX GPU 텍스처 이미지 파일 로더

!!! Tip

	이러한 라이브러리는 Vulkan을 사용하는 데 필수는 아닙니다. 하지만 Vulkan 사용을 더 쉽게 만들고, 일부는 VMA와 Volk처럼 상업 애플리케이션에서도 널리 사용됩니다.

## 프로그래밍 언어

C++ 20을 사용합니다. 주로 지정된 초기화자를 사용하기 때문입니다. 이들은 Vulkan의 장황함을 줄이고 코드 가독성을 높이는 데 도움이 됩니다. 그 외에는 현대 C++ 기능을 사용하지 않고 [C++](https://github.com/KhronosGroup/Vulkan-Hpp) 헤더 대신 C Vulkan 헤더를 사용합니다. 개인적인 선호 외에도, 이렇게 하면 다른 프로그래밍 언어를 사용하는 사람을 포함하여 이 튜토리얼을 가능한 한 접근하기 쉽게 만듭니다.

## 셰이딩 언어

Vulkan은 [SPIR-V](https://www.khronos.org/spirv/)라는 중간 형식으로 셰이더를 소비합니다. 이는 API와 실제 셰이딩 언어를 분리합니다. 처음에는 GLSL만 지원되었지만, 2026년에는 더 많고 더 나은 옵션이 있습니다. 그 중 하나는 [Slang](https://github.com/shader-slang)이며, 이것이 우리가 이 튜토리얼에서 사용할 것입니다. 이 언어 자체는 GLSL보다 더 현대적이며 몇 가지 편리한 기능을 제공합니다.

## Vulkan SDK

Vulkan 애플리케이션 개발에는 필수는 아니지만, [LunarG Vulkan SDK](https://vulkan.lunarg.com/sdk/home)는 이 튜토리얼에서 사용되는 것을 포함하여 일반적으로 사용되는 라이브러리와 도구를 설치하는 편리한 방법을 제공합니다. 따라서 설치하는 것이 좋습니다. 설치할 때 옵션인 GLM, Volk, SDL3 및 Vulkan Memory Allocator 구성 요소를 선택해야 합니다. 또는 각 저장소에서 다운로드하고 CMakeLists.txt 파일의 포함 경로를 조정할 수 있습니다.

## 검증 계층

Vulkan은 드라이버 오버헤드를 최소화하도록 설계되었습니다. 이는 *더 나은 성능*을 얻을 수 있지만, OpenGL과 같은 API가 가지고 있던 많은 안전장치를 제거하고 그 책임을 사용자에게 전달합니다. Vulkan을 잘못 사용하면 드라이버는 충돌할 수 있습니다. 따라서 애플리케이션이 한 GPU에서 작동하더라도 다른 GPU에서 작동한다는 보장이 없습니다. 반면, Vulkan 사양은 모든 기능에 대한 유효한 사용법을 정의합니다. 그리고 [검증 계층](https://github.com/KhronosGroup/Vulkan-ValidationLayers)이 있으며, 이를 확인하는 사용하기 쉬운 도구가 존재합니다.

검증 계층은 코드에서 활성화할 수 있지만, 더 쉬운 방법은 [Vulkan SDK](#vulkan-sdk)에서 제공하는 [Vulkan Configurator GUI](https://vulkan.lunarg.com/doc/view/latest/windows/vkconfig.html)를 통해 계층을 활성화하는 것입니다. 한 번 활성화되면 API의 부적절한 사용은 모두 애플리케이션의 명령줄 창에 기록됩니다.

!!! Note

	Vulkan으로 개발할 때는 항상 검증 계층을 활성화해야 합니다. 이는 다른 시스템에서 올바르게 작동하는 사양 준수 코드를 작성하는지 확인합니다.

## 그래픽 디버거

또 다른 필수적인 도구는 그래픽 디버거입니다. Visual Studio와 같은 IDE에서 사용할 수 있는 CPU 디버거와 유사하게, 이들은 GPU 측의 런타임 문제를 디버깅하는 데 도움을 줍니다. Vulkan을 지원하는 일반적인 크로스 플랫폼 및 크로스 벤더 그래픽 디버거는 [RenderDoc](https://renderdoc.org/)입니다. 이러한 디버거의 사용은 이 튜토리얼에 필수는 아니지만, 배운 내용을 기반으로 구축하고 그 과정에서 문제에 직면하면 매우 가치가 있습니다.

## 개발 환경

빌드 시스템은 [CMake](https://cmake.org/)가 됩니다. 코드를 작성하는 접근 방식과 유사하게, 가능한 한 간단하게 유지하면서 다양한 C++ 컴파일러와 IDE로 이 튜토리얼을 따를 수 있다는 추가 이점이 있습니다.

C++ IDE용 빌드 파일을 만들려면 프로젝트의 소스 폴더에서 다음과 같이 CMake를 실행합니다:

```bash
cmake -B build -G "Visual Studio 17 2022"
```

이렇게 하면 Visual Studio 2022 솔루션 파일이 `build` 폴더에 기록됩니다. 명령줄의 대안으로 [cmake-gui](https://cmake.org/cmake/help/latest/manual/cmake-gui.1.html)를 사용할 수 있습니다. 생성기(-G)는 사용하는 IDE에 따라 다르며, [여기](https://cmake.org/cmake/help/latest/manual/cmake-generators.7.html)에서 해당 목록을 찾을 수 있습니다.

## 소스 코드

이제 모든 것이 적절하게 설정되었으므로 코드의 세부 사항을 조사하기 시작할 수 있습니다. 다음 장에서는 [메인 소스 파일](https://github.com/SaschaWillems/HowToVulkan/blob/main/source/main.cpp)을 위에서 아래까지 안내합니다.

!!! Warning

	이 문서에서는 덜 흥미로운 초기화, 선언 및 보일러플레이트 코드의 일부가 생략되었습니다. 이 튜토리얼을 진행할 때 메인 소스 파일도 열어두는 것이 좋습니다.

## 인스턴스 설정

먼저 필요한 것은 Vulkan 인스턴스입니다. 이는 애플리케이션을 Vulkan에 연결하며, 그 후 모든 것의 기초가 됩니다.

인스턴스 설정은 애플리케이션에 대한 정보를 전달하는 것으로 구성됩니다:

```cpp
VkApplicationInfo appInfo{
	.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
	.pApplicationName = "How to Vulkan",
	.apiVersion = VK_API_VERSION_1_3
};
```

가장 중요한 것은 `apiVersion`으로, Vulkan에 Vulkan 1.3을 사용하고 싶다고 알려줍니다. 더 높은 API 버전을 사용하면 확장을 통해 사용해야 했던 기능을 그대로 사용할 수 있습니다. [Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html)은 널리 지원되며 Vulkan을 더 쉽게 사용하는 많은 기능이 추가되었습니다. `pApplicationName`은 애플리케이션을 식별하는 데 사용할 수 있습니다.

!!! Info

	자주 보게 될 구조체 멤버 중 하나가 `sType`입니다. 드라이버는 어떤 구조체 유형을 처리해야 하는지 알아야 하며, Vulkan이 C-API이므로 구조체 멤버를 통해 지정하는 것 외에는 다른 방법이 없습니다.

인스턴스는 또한 사용하려는 확장에 대해 알아야 합니다. 이름에서 알 수 있듯이, 이들은 API를 확장하는 데 사용됩니다. 인스턴스 생성(및 기타 일부)은 플랫폼 특정이므로, 인스턴스는 어떤 플랫폼 특정 확장을 사용하고 싶은지 알아야 합니다. 예를 들어, Windows의 경우 [VK_KHR_win32_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_win32_surface.html)를 사용하고, Android의 경우 [VK_KHR_android_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_android_surface.html)를 사용하며, 기타 플랫폼에 대해서도 마찬가지입니다.

!!! Note

	Vulkan에는 두 가지 확장 유형이 있습니다. 인스턴스 확장과 장치 확장입니다. 전자는 주로 전역이며, 종종 GPU와 독립적인 플랫폼 특정 확장이고, 후자는 GPU의 능력을 기반으로 합니다.

이는 플랫폼 특정 코드를 작성해야 한다는 것을 의미합니다. **하지만** SDL과 같은 라이브러리를 사용하면 그럴 필요가 없으며, 대신 SDL에 플랫폼 특정 인스턴스 확장을 요청합니다:

```cpp
uint32_t instanceExtensionsCount{ 0 };
char const* const* instanceExtensions{ SDL_Vulkan_GetInstanceExtensions(&instanceExtensionsCount) };
```

따라서 플랫폼 특정 사항을 걱정할 필요가 없습니다. 애플리케이션 정보와 필요한 확장이 설정되었으므로 인스턴스를 만들 수 있습니다:

```cpp
VkInstanceCreateInfo instanceCI{
	.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
	.pApplicationInfo = &appInfo,
	.enabledExtensionCount = instanceExtensionsCount,
	.ppEnabledExtensionNames = instanceExtensions,
};
chk(vkCreateInstance(&instanceCI, nullptr, &instance));
```

이것은 매우 간단합니다. 애플리케이션 정보와 SDL이 제공한 인스턴스 확장의 이름과 수(컴파일 중인 플랫폼용)를 전달합니다. [`vkCreateInstance`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateInstance.html)를 호출하면 인스턴스가 생성됩니다.

!!! Tip

	대부분의 Vulkan 함수는 다양한 방식으로 실패할 수 있으며 [`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html) 값을 반환합니다. 반환 코드를 확인하고 오류가 있으면 애플리케이션을 종료하는 작은 인라인 함수 `chk`를 사용합니다. 실제 애플리케이션에서는 더 정교한 오류 처리를 수행해야 합니다.

## 장치 선택

이제 렌더링에 사용할 장치를 선택해야 합니다. 이것은 일반적이지 않지만, 단일 시스템 내에 여러 Vulkan 지원 장치가 존재할 수 있습니다. 예를 들어, 여러 GPU가 설치되어 있거나 통합 GPU와 개별 GPU가 모두 있는 경우 등:

!!! Info

	Vulkan을 다룰 때 일반적으로 사용되는 용어는 구현입니다. 이는 Vulkan API를 구현하는 것을 나타냅니다. 일반적으로 GPU용 드라이버이지만, CPU 기반 소프트웨어 구현일 수도 있습니다. 간단하게 하기 위해 이 튜토리얼의 나머지 부분에서는 용어 GPU를 사용합니다.

그를 위해 Vulkan을 지원하는 사용 가능한 모든 물리적 장치의 목록을 가져옵니다:

```cpp
uint32_t deviceCount{ 0 };
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr));
std::vector<VkPhysicalDevice> devices(deviceCount);
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data()));
```

[`vkEnumeratePhysicalDevices`](https://docs.vulkan.org/refpages/latest/refpages/source/vkEnumeratePhysicalDevices.html)에 대한 두 번째 호출 후, 사용 가능한 모든 Vulkan 지원 장치의 목록이 있습니다.

!!! Info

	어떤 종류의 목록을 반환하는 함수를 두 번 호출해야 하는 것은 Vulkan C-API에서 일반적입니다. 첫 번째 호출은 요소 수를 반환하며, 그 다음 결과 목록의 크기를 적절하게 조정하는 데 사용됩니다. 두 번째 호출은 실제 결과 목록을 채웁니다.

대부분의 시스템에는 장치가 하나만 있으므로, 원하는 장치 인덱스를 명령줄 인수로 전달하여 장치를 선택하는 간단하고 선택적인 방법을 구현합니다:

```cpp
uint32_t deviceIndex{ 0 };
if (argc > 1) {
	deviceIndex = std::stoi(argv[1]);
	assert(deviceIndex < deviceCount);
}
```

또한 선택한 장치의 정보를 표시하고 싶습니다. 그를 위해 [`vkGetPhysicalDeviceProperties2`](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceProperties2.html)를 호출하고 장치 이름을 콘솔에 출력합니다:

```cpp
VkPhysicalDeviceProperties2 deviceProperties{ .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2 };
vkGetPhysicalDeviceProperties2(devices[deviceIndex], &deviceProperties);
std::cout << "Selected device: " << deviceProperties.properties.deviceName <<  "
";
```

!!! Info

	`VkPhysicalDeviceProperties2`와 `vkGetPhysicalDeviceProperties2`의 접미사가 `2`인 것을 눈치챘을 것입니다. 이는 [해결](https://docs.vulkan.org/spec/latest/appendices/legacy.html)하기 위해 수행되었습니다. 원래 함수와 구조체를 수정하는 것은 API 호환성이 깨지기 때문에 선택 사항이 아닙니다.

## 큐

Vulkan에서 작업은 장치에 직접 제출되는 것이 아니라 큐에 제출됩니다. 큐는 하드웨어(그래픽, 계산, 전송, 비디오 등)에 대한 액세스를 추상화합니다. 이들은 큐 패밀리로 구성되며, 각 패밀리는 공통 기능을 가진 큐 세트를 설명합니다. 사용 가능한 큐 유형은 GPU마다 다릅니다. 그래픽 작업만 수행하므로 그래픽을 지원하는 큐 패밀리 하나만 찾으면 됩니다. 이는 [`VK_QUEUE_GRAPHICS_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkQueueFlagBits.html) 플래그를 확인하여 수행됩니다:

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

해당 그래픽 큐를 사용하여 화면에 무언가를 [표시](#present-image)하려고 하므로, 해당 큐가 표시를 지원하는지도 확인합니다:

```cpp
chk(SDL_Vulkan_GetPresentationSupport(instance, devices[deviceIndex], queueFamily));
```

!!! Tip

	그래픽을 지원하는 큐 패밀리가 없는 장치는 현실에서 매우 드뭅니다. 또한 대부분의 장치에서 첫 번째 큐 패밀리는 그래픽, 계산 및 표시를 지원합니다. 위와 같이 확인하는 것은 좋은 습관이며, 특히 계산과 같은 다른 큐 유형을 사용하려는 경우 중요합니다. 그래픽, 계산 및/또는 표시에 다른 큐 패밀리가 필요한 장치를 만나면 이러한 큐 사이에 추가 동기화를 수행해야 합니다.

다음 단계에서는 [`VkDeviceQueueCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkDeviceQueueCreateInfo.html)를 사용하여 해당 큐 패밀리를 참조해야 합니다. 동일한 패밀리에서 여러 큐를 요청할 수 있지만, 그럴 필요가 없습니다. 따라서 `pQueuePriorities`에서 우선순위를 지정해야 합니다(우리의 경우 하나만 있음). 동일한 패밀리의 여러 큐의 경우, 드라이버는 해당 정보를 사용하여 작업을 우선순위로 처리할 수 있습니다:

```cpp
const float qfpriorities{ 1.0f };
VkDeviceQueueCreateInfo queueCI{
	.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
	.queueFamilyIndex = queueFamily,
	.queueCount = 1,
	.pQueuePriorities = &qfpriorities
};
```

## 장치 설정

이제 Vulkan 라이브러리에 대한 연결, 물리적 장치 선택, 사용할 큐 패밀리 파악이 되었으므로 GPU의 핸들을 가져와야 합니다. 이것은 Vulkan에서 **장치**라고 합니다. Vulkan은 물리적 장치와 논리적 장치를 구분합니다. 전자는 실제 장치(일반적으로 GPU)를 나타내고, 후자는 해당 장치의 Vulkan 구현에 대한 핸들을 나타내며 애플리케이션이 상호 작용하는 것입니다.

장치 생성의 중요한 부분 중 하나는 사용하려는 기능과 확장을 요청하는 것입니다. 인스턴스는 Vulkan 1.3을 기준선으로 생성되었으므로, 사용하려는 기능의 거의 모두가 제공됩니다. 따라서 화면에 무언가를 표시하기 위해 [`VK_KHR_swapchain`](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_swapchain.html) 확장을 요청하기만 하면 됩니다:

```cpp
const std::vector<const char*> deviceExtensions{ VK_KHR_SWAPCHAIN_EXTENSION_NAME };
```

!!! Tip

	Vulkan 헤더는 `VK_KHR_SWAPCHAIN_EXTENSION_NAME`과 같은 모든 확장에 대한 상수를 정의합니다. 이를 사용하여 이름을 문자열로 작성하는 대신 사용할 수 있습니다. 이는 확장 이름의 철자 오류를 피하는 데 도움이 됩니다.

Vulkan 1.3을 기준선으로 사용하면 [이전](#about)에 언급된 기능을 확장을 사용하지 않고 사용할 수 있습니다. 확장을 사용하면 더 많은 코드가 필요하며, 확장이 없는 경우 확인 및 대체 경로가 필요합니다. 핵심 기능의 경우, 단순히 활성화할 수 있습니다:

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

`shaderSampledImageArrayNonUniformIndexing`, `descriptorBindingVariableDescriptorCount` 및 `runtimeDescriptorArray`는 디스크립터 인덱싱과 관련이 있으며, 나머지 이름은 실제 기능과 일치합니다. 또한 더 나은 텍스처 필터링을 위해 [이방향성 필터링](https://docs.vulkan.org/refpages/latest/refpages/source/VkPhysicalDeviceFeatures.html#_members)을 활성화합니다.

!!! Info

	자주 보게 될 또 다른 Vulkan 구조체 멤버는 `pNext`입니다. 이는 함수 호출에 전달되는 구조체 연결 목록을 만드는 데 사용할 수 있습니다. 드라이버는 해당 목록의 각 구조체의 `sType` 멤버를 사용하여 해당 구조체의 유형을 식별합니다.

모든 것이 준비되었으므로 사용할 핵심 기능, 확장 및 큐 패밀리가 포함된 논리적 장치를 만들 수 있습니다:

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

또한 그래픽 명령을 제출할 큐가 필요하므로, 방금 만든 장치에서 요청할 수 있습니다:

```cpp
vkGetDeviceQueue(device, queueFamily, 0, &queue);
```

## VMA 설정

Vulkan은 명시적 API이며, 이는 메모리 관리에도 적용됩니다. 라이브러리 목록에서 언급했듯이, 이 영역을 크게 단순화하기 위해 [Vulkan 메모리 할당자(VMA)](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator)를 사용합니다.

VMA는 할당할 메모리의 할당자를 제공합니다. 이는 프로젝트에 대해 한 번 설정해야 합니다. 그를 위해 일반적인 Vulkan 함수에 대한 포인터, Vulkan 인스턴스 및 장치를 전달하고, 버퍼 디바이스 주소(`flags`) 지원도 활성화합니다:

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

	VMA도 [`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html) 반환 코드를 사용하므로, VMA 함수 결과를 확인하는 데 동일한 `chk` 함수를 사용할 수 있습니다.

## 윈도우 및 표면

Vulkan에서 무언가를 "그리기" 위해(정확한 용어는 "이미지 표시", 나중에 자세히 설명) 표면이 필요합니다. 대부분의 경우, 표면은 윈도우에서 가져옵니다. 둘 다 생성하는 것은 [인스턴스 장](#instance-setup)에서 언급했듯이 플랫폼 특정입니다. 따라서 이론적으로 이는 지원하려는 모든 플랫폼(Windows, Linux, Android 등)에 대해 다른 코드 경로를 작성해야 한다는 것을 의미합니다.

하지만 SDL과 같은 라이브러리가 그 역할을 합니다. 이들은 우리를 위해 모든 플랫폼 특정 사항을 처리하므로, 그 부분이 매우 간단해집니다.

!!! Tip

	SDL, GLFW 및 SFML과 같은 라이브러리는 또한 입력, 오디오 및 네트워킹(다양한 정도로)와 같은 기타 플랫폼 특정 기능을 처리합니다.

먼저 Vulkan 지원으로 윈도우를 만듭니다:

```cpp
SDL_Window* window = SDL_CreateWindow("How to Vulkan", 1280u, 720u, SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE);
```

그런 다음 해당 윈도우에 대한 Vulkan 표면을 요청합니다:

```cpp
chk(SDL_Vulkan_CreateSurface(window, instance, nullptr, &surface));
```

다음 장(들)에서는 방금 만든 표면의 속성을 알아야 하므로, [`vkGetPhysicalDeviceSurfaceCapabilitiesKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceSurfaceCapabilitiesKHR.html)를 통해 가져와서 나중에 참조할 수 있도록 저장합니다:

```cpp
VkSurfaceCapabilitiesKHR surfaceCaps{};
chk(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(devices[deviceIndex], surface, &surfaceCaps));
```

## 스왑체인

표면(우리의 경우 윈도우)에 시각적으로 무언가를 표시하려면 스왑체인을 만들어야 합니다. 기본적으로 색상 정보를 저장하는 일련의 이미지로, 운영 체제의 표시 엔진에 대기열에 넣습니다. [`VkSwapchainCreateInfoKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkSwapchainCreateInfoKHR.html)는 매우 광범위하며 약간의 설명이 필요합니다.

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

우리는 비선형 sRGB [색상 공간](https://docs.vulkan.org/refpages/latest/refpages/source/VkColorSpaceKHR.html) `VK_COLORSPACE_SRGB_NONLINEAR_KHR`과 함께 4 구성 요소 색상 형식 `VK_FORMAT_B8G8R8A8_SRGB`를 사용합니다. 이 조합은 어디서나 사용 가능하도록 보장됩니다. 다른 조합은 지원 확인이 필요합니다. `minImageCount`는 스왑체인에서 얻는 이미지의 최소 수입니다. 이 값은 GPU마다 다르므로, 이전에 표면에서 요청한 정보를 사용합니다. `presentMode`는 이미지가 화면에 표시되는 방식을 정의합니다. [`VK_PRESENT_MODE_FIFO_KHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPresentModeKHR.html#)는 v-동기화된 모드이며 어디서나 사용 가능하도록 보장되는 유일한 모드입니다.

!!! Note

	여기에 표시된 스왑체인 설정은 최소한입니다. 실제 애플리케이션에서는 사용자 설정에 따라 조정해야 할 수 있으므로 이 부분이 꽤 복잡할 수 있습니다. 한 가지 예는 HDR 지원 장치로, 다른 이미지 형식과 색상 공간을 사용해야 합니다.

스왑체인의 특이한 점은 이미지가 애플리케이션이 소유하지 않고 스왑체인이 소유한다는 것입니다. 따라서 명시적으로 직접 만드는 대신 스왑체인에서 요청합니다. 이렇게 하면 `minImageCount`로 설정된 것 이상의 이미지가 적어도 제공됩니다:

```cpp
uint32_t imageCount{ 0 };
chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, nullptr));
swapchainImages.resize(imageCount);
chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, swapchainImages.data()));
swapchainImageViews.resize(imageCount);
```

## 깊이 첨부

3차원 개체를 렌더링하므로, 어떤 관점에서 보든 삼각형이 래스터라이즈되는 순서에 관계없이 올바르게 표시되도록 해야 합니다. 이는 [깊이 테스트](https://docs.vulkan.org/spec/latest/chapters/fragops.html#fragops-depth)를 통해 수행되며, 이를 사용하려면 깊이 첨부가 필요합니다.

먼저 [vkGetPhysicalDeviceFormatProperties2](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceFormatProperties2.html)를 사용하여 현재 GPU에서 실제로 사용 가능한 깊이 형식이 무엇인지 확인해야 합니다:

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

	Vulkan 사양은 [보장]((https://docs.vulkan.org/spec/latest/chapters/formats.html#features-required-format-support)) 특정 형식 및 사용 조합이 모든 장치에서 지원되도록 합니다. 그러한 보장 중 하나는 깊이 형식으로, `VK_FORMAT_D32_SFLOAT_S8_UINT` 또는 `VK_FORMAT_D24_UNORM_S8_UINT` 중 하나가 깊이 첨부로 사용되도록 지원되어야 합니다.

깊이 이미지의 속성은 [`VkImageCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageCreateInfo.html) 구조체에 정의됩니다. 이 중 일부는 스왑체인 생성에서 찾을 수 있는 것과 유사합니다:

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
이미지는 2D이며 깊이를 지원하는 형식을 사용합니다. 여러 밉 레벨이나 레이어가 필요하지 않습니다. [`VK_IMAGE_TILING_OPTIMAL`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageTiling.html)을 사용하는 최적 타일링은 이미지가 GPU에 가장 적합한 형식으로 저장되도록 합니다. 또한 이미지에 대한 원하는 사용 사례를 명시해야 하며, 이는 [`VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageUsageFlagBits.html)으로 렌더 출력의 깊이 첨부로 사용합니다(나중에 자세히 설명). 초기 레이아웃은 이미지의 내용을 정의하며, 이에 대해서는 신경 쓸 필요가 없으므로 [`VK_IMAGE_LAYOUT_UNDEFINED`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html)로 설정합니다.

이것이 또한 VMA를 사용하여 Vulkan에서 무언가를 할당하는 첫 번째입니다. Vulkan에서 버퍼와 이미지에 대한 메모리 할당은 장황하지만 매우 유사합니다. VMA를 사용하면 그 중 많은 부분을 제거할 수 있습니다. VMA는 또한 올바른 메모리 유형 및 사용 플래그를 선택하는 것을 처리하며, 이는 그렇지 않으면 올바르게 얻으려면 많은 코드가 필요합니다.

```cpp
VmaAllocationCreateInfo allocCI{
	.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
chk(vmaCreateImage(allocator, &depthImageCI, &allocCI, &depthImage, &depthImageAllocation, nullptr));
```

VMA를 그렇게 편리하게 만드는 것 중 하나는 [`VMA_MEMORY_USAGE_AUTO`](https://gpuopen-librariesandsdks.github.io/VulkanMemoryAllocator/html/choosing_memory_type.html)입니다. 이 사용 플래그는 할당 및/또는 버퍼 생성 정보에 전달하는 다른 값에 따라 VMA가 필요한 사용 플래그를 자동으로 선택하도록 합니다. 사용 플래그를 명시적으로 명시하는 것이 더 나은 경우도 있지만, 대부분의 경우 자동 플래그가 완벽한 맞춤입니다. `VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT` 플래그는 VMA에 이 리소스에 대한 별도의 메모리 할당을 만들도록 지시하며, 예를 들어 큰 이미지 첨부에 대해 권장됩니다.

!!! Tip

	다른 곳에서 이중 버퍼링을 수행하더라도 이미지는 하나만 필요합니다. 이는 이미지가 GPU에 의해서만 액세스되며 GPU는 한 번에 하나의 깊이 이미지만 쓸 수 있기 때문입니다. 이는 CPU와 GPU가 공유하는 리소스와 다르지만, 나중에 자세히 설명합니다.

Vulkan의 이미지는 직접 액세스되지 않고 [뷰](https://docs.vulkan.org/spec/latest/chapters/resources.html#VkImageView)를 통해 액세스됩니다. 이는 프로그래밍에서 일반적인 개념입니다. 이는 유연성을 추가하고 동일한 이미지에 대한 다양한 액세스 패턴을 허용합니다.

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

방금 만든 이미지에 대한 뷰가 필요하며 2D 뷰로 액세스하려고 합니다. `subresourceRange`는 이 뷰를 통해 액세스하려는 이미지의 부분을 지정합니다. 여러 레이어나 (밉) 레벨이 있는 이미지의 경우 이들 중任何一个에 대해 별도의 이미지 뷰를 만들고 다양한 방식으로 이미지를 액세스할 수 있습니다. `aspectMask`는 뷰를 통해 액세스하려는 이미지의 측면을 나타냅니다. 이는 색상, 스�실, 또는 (우리의 경우) 이미지의 깊이 부분일 수 있습니다.

이미지와 이미지 뷰이 모두 생성되었으므로, 깊이 첨부를 나중에 렌더링에 사용할 준비가 되었습니다.

## 메시 로드

Vulkan의 관점에서 단일 삼각형을 그리는 것과 수천 개의 삼각형이 있는 복잡한 메시를 그리는 것 사이에는 기술적 차이가 없습니다. 둘 다 GPU가 데이터를 읽을 일종의 버퍼로 결과가 됩니다. GPU는 그 데이터가 어디에서 오는지 상관하지 않습니다. 하드코딩된 정점 데이터로 단일 삼각형을 표시하는 것으로 시작할 수 있지만, 학습 경험을 위해서는 실제 3D 개체를 로드하는 것이 훨씬 낫습니다. 이것이 다음 단계입니다.

3D 모델을 저장하는 형식은 많이 있습니다. 예를 들어 [glTF](https://www.khronos.org/Gltf)는 많은 기능을 제공하며 Vulkan과 유사한 방식으로 확장 가능합니다. 하지만 간단하게 유지하고 싶으므로, 대신 [Wavefront .obj 형식](https://en.wikipedia.org/wiki/Wavefront_.obj_file)을 사용합니다. 3D 형식으로 갈 때 이보다 더 간단한 것은 없습니다. 또한 [Blender](https://www.blender.org/)와 같은 많은 도구에서 지원됩니다.

먼저 애플리케이션에서 사용할 정점 데이터에 대한 구조체를 선언합니다. 이는 정점 위치, 정점 법선(조명에 사용), 텍스처 좌표입니다. 이들은 구어적으로 [uv](https://en.wikipedia.org/wiki/UV_mapping)로 약칭됩니다:

```cpp
struct Vertex {
	glm::vec3 pos;
	glm::vec3 normal;
	glm::vec2 uv;
};
```

[tinyobjloader 라이브러리](https://github.com/tinyobjloader/tinyobjloader)를 사용하여 .obj 파일을 로드합니다. 이는 모든 구문 분석을 수행하고 해당 파일에 포함된 데이터에 대한 구조화된 액세스를 제공합니다:

```cpp
// 메시 데이터
tinyobj::attrib_t attrib;
std::vector<tinyobj::shape_t> shapes;
std::vector<tinyobj::material_t> materials;
chk(tinyobj::LoadObj(&attrib, &shapes, &materials, nullptr, nullptr, "assets/suzanne.obj"));
```

`LoadObj`에 대한 성공적인 호출 후, 선택한 .obj 파일에 저장된 정점 데이터에 액세스할 수 있습니다. `attrib`에는 정점 데이터의 선형 배열이 포함되어 있고, `shapes`에는 해당 데이터에 대한 인덱스가 포함되어 있습니다. `materials`는 사용하지 않으며, 직접 셰이딩을 수행합니다.

!!! Warning

	.obj 형식은 다소 오래되었으며 모든 측면에서 현대 3D 파이프라인과 일치하지 않습니다. 그러한 측면 중 하나는 정점 데이터의 인덱싱입니다. .obj 파일의 구조 방식으로 인해 정점당 하나의 인덱스로 끝나며, 이는 인덱스 렌더링의 효율성을 제한합니다. 실제 애플리케이션에서는 glTF와 같이 인덱스 렌더링과 잘 작동하는 형식을 사용합니다.

인터리브된 정점 속성을 사용합니다. 인터리브된다는 것은 메모리에서 모든 정점에 대해 위치의 3개 플로트가 법선 벡터(조명에 사용)의 3개 플로트가 이어지고, 다시 텍스처 좌표의 2개 플로트가 이어진다는 것을 의미합니다.

이것이 작동하려면, tinyobj에서 제공하는 위치, 법선 및 텍스처 좌표 값을 변환해야 합니다:

```cpp
const VkDeviceSize indexCount{shapes[0].mesh.indices.size()};
std::vector<Vertex> vertices{};
std::vector<uint16_t> indices{};
// 정점 및 인덱스 데이터 로드
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

	위치와 법선의 y축 값, 텍스처 좌표의 v축 값이 뒤집습니다. 이는 Vulkan의 좌표계를 수용하기 위해 수행됩니다. 그렇지 않으면 모델과 텍스처 이미지가 거꾸로 표시됩니다.

데이터가 인터리브된 방식으로 저장되었으므로 이제 GPU에 업로드할 수 있습니다. 그를 위해 정점 및 인덱스 데이터를 보유할 버퍼를 만들어야 합니다:

```cpp
VkDeviceSize vBufSize{ sizeof(Vertex) * vertices.size() };
VkDeviceSize iBufSize{ sizeof(uint16_t) * indices.size() };
VkBufferCreateInfo bufferCI{
	.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
	.size = vBufSize + iBufSize,
	.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_INDEX_BUFFER_BIT
};
```

정점 및 인덱스에 대한 별도의 버퍼 대신 둘 다 동일한 버퍼에 넣습니다. 따라서 버퍼의 `size`는 정점 및 인덱스 벡터의 크기에서 계산됩니다. 버퍼 [`usage`](https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html) 비트 마스크 조합 `VK_BUFFER_USAGE_VERTEX_BUFFER_BIT` 및 `VK_BUFFER_USAGE_INDEX_BUFFER_BIT`는 드라이버에 의도된 사용 사례를 신호합니다.

이전에 이미지를 만든 것과 유사하게 VMA를 사용하여 정점 및 인덱스 데이터를 저장하는 버퍼를 할당합니다:

```cpp
VmaAllocationCreateInfo vBufferAllocCI{
	.flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT | VMA_ALLOCATION_CREATE_MAPPED_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
VmaAllocationInfo vBufferAllocInfo{};
chk(vmaCreateBuffer(allocator, &bufferCI, &vBufferAllocCI, &vBuffer, &vBufferAllocation, &vBufferAllocInfo));
```

다시 `VMA_MEMORY_USAGE_AUTO`를 사용하여 VMA가 버퍼에 대한 올바른 사용 플래그를 선택하도록 합니다. 여기서 사용되는 특정 `flags` 조합 `VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT` 및 `VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT`는 GPU(VRAM)에 위치하고 호스트에서 액세스할 수 있는 메모리 유형을 얻도록 합니다. 정점 및 인덱스를 CPU 메모리에 저장하는 것이 가능하지만, GPU에서의 액세스가 훨씬 느립니다. 초기에는 CPU 액세스 가능 VRAM 메모리 유형은 통합 메모리 아키텍처를 가진 시스템(모바일 또는 통합 GPU)에서만 사용 가능했습니다. 하지만 [(Re)BAR/SAM](https://en.wikipedia.org/wiki/PCI_configuration_space#Resizable_BAR) 덕분에 이제 개별 GPU도 대부분의 VRAM을 호스트 주소 공간에 매핑하고 CPU를 통해 액세스할 수 있습니다.

!!! Note

	이것이 없다면 호스트에 소위 "스테이징" 버퍼를 만들고, 그 버퍼에 데이터를 복사한 다음 명령 버퍼를 사용하여 스테이징에서 GPU 측 버퍼로 버퍼 복사를 제출해야 합니다. 이는 훨씬 더 많은 코드를 필요로 합니다.

`VMA_ALLOCATION_CREATE_MAPPED_BIT`는 영구적으로 매핑된 버퍼를 얻으며, 이를 통해 VRAM에 직접 데이터를 복사할 수 있습니다:

```cpp
memcpy(vBufferAllocInfo.pMappedData, vertices.data(), vBufSize);
memcpy(((char*)vBufferAllocInfo.pMappedData) + vBufSize, indices.data(), iBufSize);
```

## CPU 및 GPU 병렬성

그래픽 집약 애플리케이션에서 CPU는 주로 GPU에 작업을 공급하는 데 사용됩니다. OpenGL이 발명되었을 때 컴퓨터는 단일 코어가 있는 단일 CPU를 가졌습니다. 하지만 오늘날에는 모바일 장치조차 여러 코어를 가지고 있으며, Vulkan은 이러한 코어와 GPU 간에 작업이 분배되는 방식을 더 명시적으로 제어할 수 있게 합니다.

이를 통해 가능한 한 CPU와 GPU가 병렬로 작업할 수 있습니다. 따라서 GPU가 여전히 바쁜 동안 CPU는 이미 다음 "작업 패키지"를 만들기 시작할 수 있습니다. 순진한 접근 방식은 GPU가 항상 CPU를 기다리게(그 반대의 경우도) 하는 것이지만, 이는 병렬성의 모든 가능성을 없앱니다.

!!! Tip

	이것을 염두에 두면 [명령 버퍼](#command-buffers)와 같은 것이 Vulkan에 존재하는 이유와 특정 리소스를 복제하는 이유를 이해하는 데 도움이 됩니다.

그 전제 조건은 CPU와 GPU가 공유하는 리소스를 곱하는 것입니다. 그러면 GPU가 리소스 *n*을 사용하는 동안 CPU는 리소스 *n+1*을 업데이트하기 시작할 수 있습니다. 이것은 기본적으로 이중(또는 다중) 버퍼링이며, Vulkan에서는 "플라이트 인 프레임"(frames in flight)라고 자주 언급됩니다.

이론적으로 많은 플라이트 인 프레임을 가질 수 있지만, 추가된 각 플라이트 인 프레임도 대기 시간을 추가합니다. 따라서 일반적으로 2개 또는 3개의 플라이트 인 프레임만 가집니다. 코드의 맨 위에 이를 정의합니다:

```cpp
constexpr uint32_t maxFramesInFlight{ 2 };
```

이를 사용하여 CPU와 GPU가 공유하는 모든 리소스의 크기를 조정합니다:

```cpp
std::array<ShaderDataBuffer, maxFramesInFlight> shaderDataBuffers;
std::array<VkCommandBuffer, maxFramesInFlight> commandBuffers;
```

!!! Note

	플라이트 인 프레임 개념은 CPU와 GPU가 공유하는 리소스에만 적용됩니다. GPU만 사용하는 리소스는 곱할 필요가 없습니다. 이는 예를 들어 이미지에 적용됩니다.

## 셰이더 데이터 버퍼

또한 [셰이더](#the-shader)에 사용자 입력 등 CPU 측에서 변경할 수 있는 값을 전달하고 싶습니다. 그를 위해 CPU에서 쓰고 GPU에서 읽을 수 있는 버퍼를 만들 것입니다. 이러한 버퍼의 데이터는 그리기 호출의 모든 셰이더 호출에서 일정(uniform)하게 유지됩니다. 이는 GPU에 중요한 보장입니다.

전달하려는 데이터는 단일 구조체에 저장되고 연속적으로 배치되므로, 일치하는 GPU 구조체에 쉽게 복사할 수 있습니다:

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

	CPU 측과 GPU 측 간의 구조체 레이아웃을 일치시키는 것이 중요합니다. 사용하는 데이터 유형 및 배열에 따라 레이아웃은 동일해 보이지만 셰이딩 언어가 구조체 멤버를 정렬하는 방식으로 인해 실제로는 다를 수 있습니다. 수동으로 구조체를 정렬하거나 패딩하는 것 외에 이를 피하는 한 가지 방법은 Vulkan의 [VK_EXT_scalar_block_layout](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_scalar_block_layout.html) 또는 해당 Vulkan 1.2 핵심 기능(둘 다 선택 사항)을 사용하는 것입니다.

이전 Vulkan 버전을 사용한다면 이제 디스크립터를 처리해야 합니다. 이는 기본적이지만 부분적으로 제한적이고 관리하기 어려운 Vulkan의 일부입니다.

하지만 Vulkan 1.3의 [버퍼 디바이스 주소](https://docs.vulkan.org/guide/latest/buffer_device_address.html) 기능을 사용하면 (버퍼에 대한) 디스크립터를 없앨 수 있습니다. 디스크립터를 통해 액세스하는 대신 셰이더에서 포인터 구문을 사용하여 주소를 통해 버퍼에 액세스할 수 있습니다. 이는 이해하기 쉽게 만들 뿐만 아니라 일부 결합을 제거하고 더 적은 코드를 필요로 합니다.

[이전 장](#cpu-and-gpu-parallelism)에서 언급했듯이, 최대 플라이트 인 프레임 수마다 하나의 셰이더 데이터 버퍼를 만듭니다. 그러면 GPU가 다른 버퍼에서 읽는 동안 CPU에서 하나의 버퍼를 업데이트할 수 있습니다. 이는 GPU가 여전히 읽고 있는 동안 CPU가 값 업데이트를 시작하는 읽기/쓰기 위험이 발생하지 않도록 합니다:
