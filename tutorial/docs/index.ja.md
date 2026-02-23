<!--
Copyright (c) 2025-2026, Sascha Willems
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# 2026年のVulkan入門

!!! Info

	最終更新日：2026-02-21：VMAによる永続バッファーマッピング


## はじめに

[このリポジトリ](https://github.com/SaschaWillems/HowToVulkan)と付属チュートリアルは、2026年に[Vulkan](https://vulkan.org/)グラフィックスアプリケーションを作成する方法を示しています。目標は最新の機能を活用してVulkanの使用を簡素化し、その過程で基本的な色付き三角形以上のものを作成することです。

Vulkanがリリースされてから約10年が経ち、多くのことが変わりました。バージョン1.0は、デスクトップとモバイルの幅広いGPUをサポートするために多くの妥協を行う必要がありました。レンダーパスなどの初期の概念は最適ではないことが判明し、代替案に置き換えられました。APIは成熟し、レイトレーシング、ビデオアクセラレーション、機械学習などの新しい領域が追加されました。APIと同じくらい重要なのがエコシステムであり、これも大きく変化し、GLSL以外の言語でシェーダーを記述したり、Vulkanを支援するツールを使用する新しい選択肢が提供されています。

そのため、このチュートリアルでは[Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html)をベースラインとして使用します。これにより、幅広いGPUとプラットフォームをサポートしながら、Vulkanを使いやすくするいくつかの機能にアクセスできます。使用する機能は以下の通りです：

* [ダイナミックレンダリング](https://www.khronos.org/blog/streamlining-render-passes) - レンダーパスの設定を大幅に簡素化、Vulkanで最も批判されている領域の1つ
* [バッファーデバイスアドレス](https://docs.vulkan.org/guide/latest/buffer_device_address.html) - ディスクリプタを介さずにポインタでバッファーにアクセス可能
* [ディスクリプタインデックス](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html) - ディスクリプタ管理を簡素化、しばしば"バインドレス"(bindless)と呼ばれる
* [同期2](https://docs.vulkan.org/guide/latest/extensions/VK_KHR_synchronization2.html) - 同期処理を改善、Vulkanで最も困難な領域の1つ

要約すると：2026年のVulkanは2016年のVulkanとは大きく異なる可能性があります。これが本チュートリアルで示したいことです。

!!! Tip

	少なくともVulkan 1.3をサポートするデバイスのリストは[ここ](https://vulkan.gpuinfo.org/listdevices.php?apiversion=1.3)で見つけることができます。


## 対象読者

このチュートリアルは、実際のVulkanコードを記述し、できるだけ早く（おそらく午後のうちに）動作させることに焦点を当てています。プログラミング、ソフトウェアアーキテクチャ、グラフィックスの概念、またはVulkanの仕組み（詳細）については説明しません。代わりに、[Vulkan仕様](https://docs.vulkan.org/)などの関連情報へのリンクを頻繁に含めます。少なくともC/C++とリアルタイムグラフィックスの概念の基本的な知識が必要です。

## 目標

ラスタライズに焦点を当て、Vulkanの他の部分（計算やレイトレーシングなど）は扱いません。最終的には、マウスで回転できる複数の照明とテクスチャが適用された3Dオブジェクトを画面に表示します（[スクリーンショット](images/screenshot.png)）。ソースコードは単一のファイルで数百行のコードからなり、抽象化、読みにくい現代のC++言語機能、オブジェクト指向のトリックはありません。抽象化の複数のレイヤーを通過することなく、ソースコードを上から下まで追うことができるため、はるかに理解しやすいと考えています。

## ライセンス

著作権 (c) 2025-2026, [Sascha Willems](https://www.saschawillems.de)。このドキュメントの内容は[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)ライセンスの下でライセンスされています。ソースコードのリストとファイルはMITライセンスの下でライセンスされています。

## ライブラリ

Vulkanは明示的な低レベルAPIです。そのコードを記述するのは非常に冗長になる可能性があります。興味深い部分に集中するために、以下のライブラリを使用します：

* [SDL](https://www.libsdl.org/) - ウィンドウと入力（およびこのチュートリアルでは使用されないその他の機能）。このようなライブラリがなければ、多くのプラットフォーム固有のコードを記述する必要があります。代替案は[GLFW](https://www.glfw.org/)と[SFML](https://www.sfml-dev.org/)です。これらの中でSDLが最も広範なプラットフォームをサポートしています
* [Volk](https://github.com/zeux/volk) - Vulkan関数の読み込みを簡素化するメタローダー
* [VMA](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator) - メモリ割り当ての処理を簡素化します。メモリ管理周りの冗長さを軽減します
* [glm](https://github.com/g-truc/glm) - 行列やベクトルなどをサポートする数学ライブラリ
* [tinyobjloader](https://github.com/tinyobjloader/tinyobjloader) - obj 3D形式のシングルヘッダーローダー
* [KTX-Software](https://github.com/KhronosGroup/KTX-Software) - Khronos KTX GPUテクスチャ画像ファイルローダー

!!! Tip

	これらのライブラリはVulkanを使用するために必須ではありません。しかし、Vulkanの使用を容易にし、VMAやVolkの一部は商用アプリケーションでも広く使用されています。

## プログラミング言語

C++ 20を使用します。主に指定された初期化子を使用するためです。これらはVulkanの冗長性を軽減し、コードの可読性を向上させます。それ以外では、現代のC++機能は使用せず、[C++](https://github.com/KhronosGroup/Vulkan-Hpp)ヘッダーではなくC Vulkanヘッダーを使用します。個人的な好みに加え、これにより他のプログラミング言語を使用する人を含め、このチュートリアルをできるだけアプローチしやすくしています。

## シェーディング言語

Vulkanは[SPIR-V](https://www.khronos.org/spirv/)と呼ばれる中間形式でシェーダーを受け取ります。これにより、APIと実際のシェーディング言語が切り離されます。当初はGLSLのみがサポートされていましたが、2026年にはより多くの優れたオプションがあります。その1つが[Slang](https://github.com/shader-slang)であり、このチュートリアルで使用するものです。この言語自体はGLSLよりも現代的で、いくつかの便利な機能を提供しています。

## Vulkan SDK

Vulkanアプリケーションの開発には必須ではありませんが、[LunarG Vulkan SDK](https://vulkan.lunarg.com/sdk/home)は、このチュートリアルで使用されるものを含む一般的に使用されるライブラリとツールをインストールする便利な方法を提供します。そのため、インストールすることをお勧めします。インストール時、オプションのGLM、Volk、SDL3、Vulkan Memory Allocatorコンポーネントを選択してください。または、それぞれのリポジトリからダウンロードし、CMakeLists.txtファイルのインクルードパスを調整できます。

## 検証レイヤー

Vulkanはドライバのオーバーヘッドを最小限に抑えるように設計されています。これにより*より良いパフォーマンス*が得られる可能性がありますが、OpenGLなどのAPIが持っていた多くの保護機能が削除され、その責任があなたに委ねられます。Vulkanを誤って使用すると、ドライバはクラッシュする可能性があります。したがって、アプリケーションが1つのGPUで動作しても、他のGPUで動作するとは限りません。一方で、Vulkan仕様はすべての機能の有効な使用法を定義しています。そして、[検証レイヤー](https://github.com/KhronosGroup/Vulkan-ValidationLayers)があり、それをチェックするための使いやすいツールが存在します。

検証レイヤーはコードで有効にできますが、より簡単な方法は[Vulkan SDK](#vulkan-sdk)によって提供される[Vulkan Configurator GUI](https://vulkan.lunarg.com/doc/view/latest/windows/vkconfig.html)を通じてレイヤーを有効にすることです。一度有効にすると、APIの不適切な使用はすべてアプリケーションのコマンドラインウィンドウに記録されます。

!!! Note

	Vulkanで開発する際は、常に検証レイヤーを有効にする必要があります。これにより、他のシステムで正しく動作する仕様に準拠したコードを記述していることが保証されます。

## グラフィックスデバッガ

もう1つの不可欠なツールはグラフィックスデバッガです。Visual StudioなどのIDEで利用可能なCPUデバッガと同様に、これらはGPU側のランタイム問題のデバッグに役立ちます。Vulkanをサポートする一般的なクロスプラットフォームおよびクロスベンダーのグラフィックスデバッガは[RenderDoc](https://renderdoc.org/)です。このようなデバッガの使用はこのチュートリアルには必須ではありませんが、学んだことを基に構築し、その過程で問題に遭遇した場合、非常に価値があります。

## 開発環境

ビルドシステムは[CMake](https://cmake.org/)になります。コードを記述するアプローチと同様に、できるだけシンプルに保ち、様々なC++コンパイラとIDEでこのチュートリアルに従うことができるという追加の利点があります。

C++ IDE用のビルドファイルを作成するには、プロジェクトのソースフォルダでCMakeを次のように実行します：

```bash
cmake -B build -G "Visual Studio 17 2022"
```

これにより、Visual Studio 2022ソリューションファイルが`build`フォルダに書き込まれます。コマンドラインの代替案として、[cmake-gui](https://cmake.org/cmake/help/latest/manual/cmake-gui.1.html)を使用できます。ジェネレーター(-G)は使用するIDEによって異なり、[ここ](https://cmake.org/cmake/help/latest/manual/cmake-generators.7.html)でそのリストを見つけることができます。

## ソースコード

これですべてが適切に設定されたので、コードの詳細を調べ始めることができます。以下の章では、[メインソースファイル](https://github.com/SaschaWillems/HowToVulkan/blob/main/source/main.cpp)を上から下まで案内します。

!!! Warning

	このドキュメントでは、あまり興味深くない初期化、宣言、ボイラープレートコードの一部は省略されています。このチュートリアルを行う際は、メインソースファイルも開いておくことをお勧めします。

## インスタンスの設定

最初に必要なのはVulkanインスタンスです。これはアプリケーションをVulkanに接続し、その後のすべての基礎となります。

インスタンスの設定は、アプリケーションに関する情報を渡すことから成ります：

```cpp
VkApplicationInfo appInfo{
	.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
	.pApplicationName = "How to Vulkan",
	.apiVersion = VK_API_VERSION_1_3
};
```

最も重要なのは`apiVersion`で、VulkanにVulkan 1.3を使用したいことを伝えます。より高いAPIバージョンを使用すると、拡張機能を使用する必要があった機能をそのまま使用できます。[Vulkan 1.3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_VERSION_1_3.html)は広くサポートされており、Vulkanをより使いやすくする多くの機能が追加されています。`pApplicationName`はアプリケーションを識別するために使用できます。

!!! Info

	頻繁に見かける構造体メンバーの1つが`sType`です。ドライバはどの構造体型を扱う必要があるかを知る必要があり、VulkanがC-APIであるため、構造体メンバーを介して指定する以外に方法はありません。

インスタンスはまた、使用したい拡張機能について知る必要があります。名前が示すように、これらはAPIを拡張するために使用されます。インスタンスの作成（およびその他の一部）はプラットフォーム固有であるため、インスタンスはどのプラットフォーム固有の拡張機能を使用したいかを知る必要があります。例えば、Windowsの場合は[VK_KHR_win32_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_win32_surface.html)を使用し、Androidの場合は[VK_KHR_android_surface](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_android_surface.html)を使用し、他のプラットフォームについても同様です。

!!! Note

	Vulkanには2種類の拡張機能があります。インスタンス拡張機能とデバイス拡張機能です。前者は主にグローバルで、GPUに依存しないプラットフォーム固有の拡張機能であり、後者はGPUの能力に基づいています。

これはプラットフォーム固有のコードを記述する必要があることを意味します。**しかし**、SDLのようなライブラリを使用すると、その必要はなくなり、代わりにSDLにプラットフォーム固有のインスタンス拡張機能を要求します：

```cpp
uint32_t instanceExtensionsCount{ 0 };
char const* const* instanceExtensions{ SDL_Vulkan_GetInstanceExtensions(&instanceExtensionsCount) };
```

したがって、プラットフォーム固有のことを心配する必要はありません。アプリケーション情報と必要な拡張機能が設定されたので、インスタンスを作成できます：

```cpp
VkInstanceCreateInfo instanceCI{
	.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
	.pApplicationInfo = &appInfo,
	.enabledExtensionCount = instanceExtensionsCount,
	.ppEnabledExtensionNames = instanceExtensions,
};
chk(vkCreateInstance(&instanceCI, nullptr, &instance));
```

これは非常にシンプルです。アプリケーション情報と、SDLが提供したインスタンス拡張機能の名前と数（コンパイルしているプラットフォーム用）を渡します。[`vkCreateInstance`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateInstance.html)を呼び出すと、インスタンスが作成されます。

!!! Tip

	ほとんどのVulkan関数は様々な方法で失敗する可能性があり、[`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html)値を返します。戻りコードをチェックし、エラーの場合はアプリケーションを終了する小さなインライン関数`chk`を使用します。実際のアプリケーションでは、より高度なエラー処理を行う必要があります。

## デバイスの選択

次に、レンダリングに使用するデバイスを選択する必要があります。これは一般的ではありませんが、単一のシステム内に複数のVulkan対応デバイスが存在する可能性があります。例えば、複数のGPUがインストールされている場合や、統合GPUとディスクリートGPUの両方がある場合などです：

!!! Info

	Vulkanを扱う際、一般的に使用される用語は実装です。これはVulkan APIを実装するものを指します。通常はGPUのドライバですが、CPUベースのソフトウェア実装である可能性もあります。簡潔にするため、このチュートリアルの残りの部分では用語GPUを使用します。

そのために、Vulkanをサポートするすべての利用可能な物理デバイスのリストを取得します：

```cpp
uint32_t deviceCount{ 0 };
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr));
std::vector<VkPhysicalDevice> devices(deviceCount);
chk(vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data()));
```

[`vkEnumeratePhysicalDevices`](https://docs.vulkan.org/refpages/latest/refpages/source/vkEnumeratePhysicalDevices.html)への2回目の呼び出しの後、利用可能なすべてのVulkan対応デバイスのリストができあがります。

!!! Info

	何らかのリストを返す関数を2回呼び出す必要があることは、Vulkan C-APIでは一般的です。最初の呼び出しは要素の数を返し、それを使用して結果リストのサイズを適切に調整します。2回目の呼び出しは実際の結果リストを埋めます。

ほとんどのシステムにはデバイスが1つしかないため、目的のデバイスインデックスをコマンドライン引数として渡すことでデバイスを選択する簡単でオプションの方法を実装します：

```cpp
uint32_t deviceIndex{ 0 };
if (argc > 1) {
	deviceIndex = std::stoi(argv[1]);
	assert(deviceIndex < deviceCount);
}
```

また、選択したデバイスの情報を表示したいと考えます。そのために、[`vkGetPhysicalDeviceProperties2`](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceProperties2.html)を呼び出し、デバイス名をコンソールに出力します：

```cpp
VkPhysicalDeviceProperties2 deviceProperties{ .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2 };
vkGetPhysicalDeviceProperties2(devices[deviceIndex], &deviceProperties);
std::cout << "Selected device: " << deviceProperties.properties.deviceName <<  "
";
```

!!! Info

	`VkPhysicalDeviceProperties2`と`vkGetPhysicalDeviceProperties2`のサフィックスが`2`であることに気づいたかもしれません。これは[対処](https://docs.vulkan.org/spec/latest/appendices/legacy.html)するために行われました。元の関数と構造体を修正することは選択肢ではなく、API互換性が破壊されるためです。

## キュー

Vulkanでは、作業はデバイスに直接送信されるのではなく、キューに送信されます。キューはハードウェア（グラフィックス、計算、転送、ビデオなど）へのアクセスを抽象化します。それらはキューファミリーに編成され、各ファミリーは共通の機能を持つキューのセットを記述します。使用可能なキュータイプはGPUによって異なります。グラフィックス操作のみを行うため、グラフィックスをサポートするキューファミリーを1つ見つける必要があります。これは[`VK_QUEUE_GRAPHICS_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkQueueFlagBits.html)フラグをチェックすることで行われます：

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

そのグラフィックスキューを使用して画面に何かを[表示](#present-image)するため、そのキューが表示をサポートしているかもチェックします：

```cpp
chk(SDL_Vulkan_GetPresentationSupport(instance, devices[deviceIndex], queueFamily));
```

!!! Tip

	グラフィックスをサポートするキューファミリーがないデバイスは現実には非常にまれです。また、ほとんどのデバイスでは、最初のキューファミリーがグラフィックス、計算、表示をサポートしています。上記のようにチェックすることは良い習慣であり、特に計算などの他のキュータイプを使用する場合には重要です。グラフィックス、計算、および/または表示に異なるキューファミリーが必要なデバイスに遭遇した場合、これらのキュー間で追加の同期を行う必要があります。

次のステップでは、[`VkDeviceQueueCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkDeviceQueueCreateInfo.html)を使用してそのキューファミリーを参照する必要があります。同じファミリーから複数のキューを要求することは可能ですが、必要ありません。そのため、`pQueuePriorities`で優先度を指定する必要があります（当社の場合は1つだけ）。同じファミリーからの複数のキューの場合、ドライバはその情報を使用して作業を優先する場合があります：

```cpp
const float qfpriorities{ 1.0f };
VkDeviceQueueCreateInfo queueCI{
	.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
	.queueFamilyIndex = queueFamily,
	.queueCount = 1,
	.pQueuePriorities = &qfpriorities
};
```

## デバイスの設定

これでVulkanライブラリへの接続、物理デバイスの選択、使用するキューファミリーの把握ができたので、GPUのハンドルを取得する必要があります。これはVulkanでは**デバイス**と呼ばれます。Vulkanは物理デバイスと論理デバイスを区別します。前者は実際のデバイス（通常はGPU）を表し、後者はそのデバイスのVulkan実装へのハンドルを表し、アプリケーションが対話するものです。

デバイス作成の重要な部分の1つは、使用したい機能と拡張機能を要求することです。インスタンスはVulkan 1.3をベースラインとして作成されており、使用したい機能のほぼすべてが提供されます。したがって、画面に何かを表示するために[`VK_KHR_swapchain`](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_swapchain.html)拡張機能を要求するだけで済みます：

```cpp
const std::vector<const char*> deviceExtensions{ VK_KHR_SWAPCHAIN_EXTENSION_NAME };
```

!!! Tip

	Vulkanヘッダーは、`VK_KHR_SWAPCHAIN_EXTENSION_NAME`のように、すべての拡張機能の定数を定義しています。名前を文字列として記述するのではなく、これらの定数を使用できます。これにより、拡張機能名のスペルミスを回避できます。

Vulkan 1.3をベースラインとして使用すると、拡張機能に頼ることなく、[前述](#about)の機能を使用できます。拡張機能を使用する場合、より多くのコードが必要になり、拡張機能が存在しない場合のチェックとフォールバックパスが必要になります。コア機能の場合は、単純に有効にできます：

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

`shaderSampledImageArrayNonUniformIndexing`、`descriptorBindingVariableDescriptorCount`、および`runtimeDescriptorArray`はディスクリプタインデックスに関連しており、残りの名前は実際の機能と一致します。また、より良いテクスチャフィルタリングのために[異方性フィルタリング](https://docs.vulkan.org/refpages/latest/refpages/source/VkPhysicalDeviceFeatures.html#_members)を有効にします。

!!! Info

	頻繁に見かけるもう1つのVulkan構造体メンバーは`pNext`です。これは、関数呼び出しに渡される構造体の連結リストを作成するために使用できます。ドライバはそのリスト内の各構造体の`sType`メンバーを使用して、その構造体の型を識別します。

すべてが揃ったので、使用するコア機能、拡張機能、キューファミリーを含む論理デバイスを作成できます：

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

また、グラフィックスコマンドを送信するキューが必要で、今作成したデバイスから要求できます：

```cpp
vkGetDeviceQueue(device, queueFamily, 0, &queue);
```

## VMAの設定

Vulkanは明示的なAPIであり、これはメモリ管理にも適用されます。ライブラリのリストで述べたように、[Vulkanメモリアロケータ(VMA)](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator)を使用して、この領域を大幅に簡素化します。

VMAはメモリを割り当てるためのアロケータを提供します。これはプロジェクトごとに1回設定する必要があります。そのために、いくつかの一般的なVulkan関数へのポインタ、Vulkanインスタンスとデバイスを渡し、バッファーデバイスアドレス(`flags`)のサポートも有効にします：

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

	VMAも[`VkResult`](https://docs.vulkan.org/refpages/latest/refpages/source/VkResult.html)戻りコードを使用するため、同じ`chk`関数を使用してVMAの関数結果をチェックできます。

## ウィンドウとサーフェス

Vulkanで何かを「描画」するには（正しい用語は「イメージを表示」ですが、後で詳しく説明します）、サーフェスが必要です。ほとんどの場合、サーフェスはウィンドウから取得されます。[インスタンスの章](#instance-setup)で述べたように、両方の作成はプラットフォーム固有です。したがって、理論的には、サポートしたいすべてのプラットフォーム（Windows、Linux、Androidなど）で異なるコードパスを記述する必要があります。

しかし、そこでSDLのようなライブラリが登場します。これらはすべてのプラットフォーム固有の詳細を処理してくれるため、その部分は非常にシンプルになります。

!!! Tip

	SDL、GLFW、SFMLのようなライブラリは、入力、オーディオ、ネットワーキ（程度は異なりますが）などの他のプラットフォーム固有の機能も処理します。

まず、Vulkanサポート付きのウィンドウを作成します：

```cpp
SDL_Window* window = SDL_CreateWindow("How to Vulkan", 1280u, 720u, SDL_WINDOW_VULKAN | SDL_WINDOW_RESIZABLE);
```

次に、そのウィンドウ用のVulkanサーフェスを要求します：

```cpp
chk(SDL_Vulkan_CreateSurface(window, instance, nullptr, &surface));
```

次の章で、作成したサーフェスのプロパティを知る必要があるため、[`vkGetPhysicalDeviceSurfaceCapabilitiesKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceSurfaceCapabilitiesKHR.html)を介してそれらを取得し、将来の参照のために保存します：

```cpp
VkSurfaceCapabilitiesKHR surfaceCaps{};
chk(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(devices[deviceIndex], surface, &surfaceCaps));
```

## スワップチェーン

サーフェス（この場合はウィンドウ）に視覚的に何かを表示するには、スワップチェーンを作成する必要があります。これは基本的に、オペレーティングシステムの表示エンジンにエンキューされる色情報を格納する一連のイメージです。[`VkSwapchainCreateInfoKHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkSwapchainCreateInfoKHR.html)は非常に広範囲であり、いくつかの説明が必要です。

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

非線形sRGB[カラースペース](https://docs.vulkan.org/refpages/latest/refpages/source/VkColorSpaceKHR.html)`VK_COLORSPACE_SRGB_NONLINEAR_KHR`を持つ4成分カラーフォーマット`VK_FORMAT_B8G8R8A8_SRGB`を使用しています。この組み合わせはどこでも利用可能であることが保証されています。異なる組み合わせを使用するには、サポートを確認する必要があります。`minImageCount`はスワップチェーンから取得するイメージの最小数です。この値はGPUによって異なるため、以前にサーフェスから要求した情報を使用します。`presentMode`はイメージが画面に表示される方法を定義します。[`VK_PRESENT_MODE_FIFO_KHR`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPresentModeKHR.html#)はv同期モードであり、どこでも利用可能であることが保証されている唯一のモードです。

!!! Note

	ここに示すスワップチェーンの設定は最低限です。実際のアプリケーションでは、ユーザー設定に基づいて調整する必要があるため、この部分は非常に複雑になる可能性があります。HDR対応デバイスなどの例では、異なるイメージフォーマットとカラースペースを使用する必要があります。

スワップチェーンの特別な点は、そのイメージがアプリケーションによって所有されるのではなく、スワップチェーンによって所有されることです。したがって、明示的にそれらを作成するのではなく、スワップチェーンから要求します。これにより、`minImageCount`で設定した数以上のイメージが少なくとも得られます：

```cpp
uint32_t imageCount{ 0 };
chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, nullptr));
swapchainImages.resize(imageCount);
chk(vkGetSwapchainImagesKHR(device, swapchain, &imageCount, swapchainImages.data()));
swapchainImageViews.resize(imageCount);
```

## 深度アタッチメント

3Dオブジェクトをレンダリングするため、どの角度から見ても、または三角形がラスタライズされる順序に関係なく、それらが正しく表示されるようにする必要があります。これは[深度テスト](https://docs.vulkan.org/spec/latest/chapters/fragops.html#fragops-depth)を通じて行われ、それを使用するには深度アタッチメントが必要です。

まず、現在のGPUで実際に使用可能な深度フォーマットを[vkGetPhysicalDeviceFormatProperties2](https://docs.vulkan.org/refpages/latest/refpages/source/vkGetPhysicalDeviceFormatProperties2.html)を使用して確認する必要があります：

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

	Vulkan仕様は、すべてのデバイスでサポートされる特定のフォーマットと使用法の組み合わせを[保証](https://docs.vulkan.org/spec/latest/chapters/formats.html#features-required-format-support)しています。そのような保証の1つは深度フォーマットに対するものであり、`VK_FORMAT_D32_SFLOAT_S8_UINT`または`VK_FORMAT_D24_UNORM_S8_UINT`のいずれかが深度アタッチメントとして使用するためにサポートされている必要があります。

深度イメージのプロパティは[`VkImageCreateInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageCreateInfo.html)構造体で定義されます。その一部はスワップチェーンの作成時に見られるものと似ています：

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
イメージは2Dであり、深度をサポートするフォーマットを使用します。複数のミップレベルやレイヤーは必要ありません。[`VK_IMAGE_TILING_OPTIMAL`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageTiling.html)による最適タイリングを使用すると、イメージがGPUに最適な形式で保存されます。また、イメージの目的の使用法を指定する必要があります。これはレンダリング出力の深度アタッチメントとして使用するための[`VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageUsageFlagBits.html)です（後で詳しく説明します）。初期レイアウトはイメージの内容を定義し、気にする必要がないため、[`VK_IMAGE_LAYOUT_UNDEFINED`](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html)に設定します。

これがVMAを使用してVulkanで何かを割り当てる最初の機会です。Vulkanでのバッファーとイメージのメモリ割り当ては冗長ですが、非常に似ています。VMAを使用すると、その多くを取り除くことができます。VMAはまた、適切なメモリタイプと使用フラグの選択を処理し、それ以外の場合は正しく取得するために多くのコードが必要になります。

```cpp
VmaAllocationCreateInfo allocCI{
	.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
chk(vmaCreateImage(allocator, &depthImageCI, &allocCI, &depthImage, &depthImageAllocation, nullptr));
```

VMAを非常に便利にするものの1つは[`VMA_MEMORY_USAGE_AUTO`](https://gpuopen-librariesandsdks.github.io/VulkanMemoryAllocator/html/choosing_memory_type.html)です。この使用フラグは、割り当ておよび/またはバッファー作成情報のために渡す他の値に基づいて、VMAが必要な使用フラグを自動的に選択するようにします。使用フラグを明示的に指定した方が良い場合もありますが、ほとんどの場合、自動フラグが完璧に適合します。`VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT`フラグは、VMAにこのリソース用の別個のメモリ割り当てを作成するように指示し、大きなイメージアタッチメントなどにお勧めです。

!!! Tip

	他の場所でダブルバッファリングを行っていても、イメージは1つだけで十分です。これはイメージがGPUのみによってアクセスされ、GPUが一度に1つの深度イメージにしか書き込めないためです。これはCPUとGPUで共有されるリソースとは異なりますが、後で詳しく説明します。

Vulkanのイメージは直接アクセスされず、[ビュー](https://docs.vulkan.org/spec/latest/chapters/resources.html#VkImageView)を介してアクセスされます。これはプログラミングで一般的な概念です。これにより柔軟性が追加され、同じイメージに対して異なるアクセスパターンが可能になります。

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

作成したイメージのビューが必要で、それを2Dビューとしてアクセスしたいと考えます。`subresourceRange`はこのビューを介してアクセスしたいイメージの部分を指定します。複数のレイヤーまたは（ミップ）レベルを持つイメージの場合、それらのそれぞれに別々のイメージビューを作成し、イメージを異なる方法でアクセスできます。`aspectMask`はビューを介してアクセスしたいイメージの側面を指します。これは色、ステンシル、または（この場合は）イメージの深度部分です。

イメージとイメージビューの両方を作成したので、深度アタッチメントは後でレンダリングに使用できるようになりました。

## メッシュの読み込み

Vulkanの観点からは、単一の三角形を描画することと数千の三角形を持つ複雑なメッシュを描画することに技術的な違いはありません。両方ともGPUがデータを読み取る何らかのバッファーになります。GPUはそのデータがどこから来るかを気にしません。ハードコードされた頂点データで単一の三角形を表示することから始めることもできますが、学習体験としては実際の3Dオブジェクトをロードする方がはるかに優れています。これが次のステップです。

3Dモデルを保存するためのフォーマットは多数あります。例えば、[glTF](https://www.khronos.org/Gltf)は多くの機能を提供し、Vulkanに似た方法で拡張可能です。しかし、シンプルに保つために、代わりに[Wavefront .obj形式](https://en.wikipedia.org/wiki/Wavefront_.obj_file)を使用します。3D形式としては、これ以上シンプルなものはありません。また、[Blender](https://www.blender.org/)などの多くのツールでサポートされています。

まず、アプリケーションで使用する予定の頂点データの構造体を宣言します。これは頂点位置、頂点法線（照明に使用）、およびテクスチャ座標です。これらは口頭的に[uv](https://en.wikipedia.org/wiki/UV_mapping)と略されます：

```cpp
struct Vertex {
	glm::vec3 pos;
	glm::vec3 normal;
	glm::vec2 uv;
};
```

[tinyobjloaderライブラリ](https://github.com/tinyobjloader/tinyobjloader)を使用して.objファイルをロードします。これはすべての解析を行い、そのファイルに含まれるデータへの構造化されたアクセスを提供します：

```cpp
// Mesh data
tinyobj::attrib_t attrib;
std::vector<tinyobj::shape_t> shapes;
std::vector<tinyobj::material_t> materials;
chk(tinyobj::LoadObj(&attrib, &shapes, &materials, nullptr, nullptr, "assets/suzanne.obj"));
```

`LoadObj`への呼び出しが成功すると、選択した.objファイルに保存されている頂点データにアクセスできます。`attrib`には頂点データの線形配列が含まれ、`shapes`にはそのデータへのインデックスが含まれます。`materials`は使用せず、独自のシェーディングを行います。

!!! Warning

	.obj形式は少し古く、現代の3Dパイプラインのすべての面で一致しません。そのような面の1つは頂点データのインデックス作成です。.objファイルが構造されている方法により、頂点ごとに1つのインデックスになり、インデックス付きレンダリングの効果が制限されます。実際のアプリケーションでは、glTFのようなインデックス付きレンダリングでうまく機能する形式を使用します。

インターリーブされた頂点属性を使用します。インターリーブとは、メモリ内で、各頂点の位置の3つのfloatの後に法線ベクトル（照明に使用）の3つのfloatが続き、その後にテクスチャ座標の2つのfloatが続くことを意味します。

それを機能させるには、tinyobjが提供する位置、法線、テクスチャ座標の値データを変換する必要があります：

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

	位置と法線のy軸、およびテクスチャ座標のv軸の値が反転されています。これはVulkanの座標系に適応するために行われます。そうしないと、モデルとテクスチャ画像が上下逆に表示されます。

データがインターリーブ方式で保存されたので、それをGPUにアップロードできます。そのために、頂点とインデックスデータを保持するバッファーを作成する必要があります：

```cpp
VkDeviceSize vBufSize{ sizeof(Vertex) * vertices.size() };
VkDeviceSize iBufSize{ sizeof(uint16_t) * indices.size() };
VkBufferCreateInfo bufferCI{
	.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
	.size = vBufSize + iBufSize,
	.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_INDEX_BUFFER_BIT
};
```

頂点とインデックス用に別々のバッファーを持つのではなく、両方を同じバッファーに入れます。そのため、バッファーの`size`は頂点とインデックスベクトルのサイズから計算されます。バッファー[`usage`](https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html)ビットマスクの`VK_BUFFER_USAGE_VERTEX_BUFFER_BIT`と`VK_BUFFER_USAGE_INDEX_BUFFER_BIT`の組み合わせは、ドライバに目的の使用法を通知します。

以前のイメージの作成と同様に、VMAを使用して頂点とインデックスデータを保存するバッファーを割り当てます：

```cpp
VmaAllocationCreateInfo vBufferAllocCI{
	.flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT | VMA_ALLOCATION_CREATE_MAPPED_BIT,
	.usage = VMA_MEMORY_USAGE_AUTO
};
VmaAllocationInfo vBufferAllocInfo{};
chk(vmaCreateBuffer(allocator, &bufferCI, &vBufferAllocCI, &vBuffer, &vBufferAllocation, &vBufferAllocInfo));
```

再び`VMA_MEMORY_USAGE_AUTO`を使用して、VMAにバッファーの適切な使用フラグを選択させます。ここで使用される`VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT`と`VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT`の特定の`flags`の組み合わせは、GPU上（VRAM内）にあり、ホストからアクセス可能なメモリタイプを取得することを確実にします。頂点とインデックスをCPUメモリに保存することは可能ですが、GPUによるアクセスははるかに遅くなります。当初、CPUアクセス可能なVRAMメモリタイプは、モバイルや統合GPUなど、統合メモリアーキテクチャを持つシステムでのみ利用可能でした。しかし、[(Re)BAR/SAM](https://en.wikipedia.org/wiki/PCI_configuration_space#Resizable_BAR)のおかげで、現在では専用GPUでさえもVRAMの大部分をホストアドレス空間にマッピングし、CPUを介してアクセスできるようになっています。

!!! Note

	これがない場合、ホスト上にいわゆる「ステージング」バッファーを作成し、データをそのバッファーにコピーしてから、コマンドバッファーを使用してステージングからGPU側バッファーへのバッファーコピーを送信する必要があります。これにははるかに多くのコードが必要になります。

`VMA_ALLOCATION_CREATE_MAPPED_BIT`は永続的にマップされたバッファーを取得し、VRAMに直接データをコピーできるようにします：

```cpp
memcpy(vBufferAllocInfo.pMappedData, vertices.data(), vBufSize);
memcpy(((char*)vBufferAllocInfo.pMappedData) + vBufSize, indices.data(), iBufSize);
```

## CPUとGPUの並列処理

グラフィックスを多用するアプリケーションでは、CPUは主にGPUに作業を供給するために使用されます。OpenGLが発明されたとき、コンピュータには単一コアを持つ単一のCPUがありました。しかし今日では、モバイルデバイスでさえも複数のコアがあり、Vulkanは作業がこれらとGPUの間でどのように分散されるかについてより明示的な制御を提供します。

これにより、可能な限りCPUとGPUを並行して動作させることができます。したがって、GPUがまだビジー状態の間、CPUですでに次の「作業パッケージ」の作成を開始できます。単純なアプローチでは、GPUが常にCPUを待機させ（その逆も同様）、並列処理のあらゆる可能性が失われます。

!!! Tip

	これを念頭に置くと、Vulkanに[コマンドバッファー](#command-buffers)のようなものが存在する理由、および特定のリソースを複製する理由を理解するのに役立ちます。

そのための前提条件は、CPUとGPUで共有されるリソースを増やすことです。そうすることで、GPUがまだリソース*n*を使用している間に、CPUがリソース*n+1*の更新を開始できます。これは基本的にダブル（またはマルチ）バッファリングであり、Vulkanでは「フライト中のフレーム」と呼ばれます。

理論的には多くのフライト中のフレームを持つことができますが、追加された各フライト中のフレームもレイテンシを追加します。したがって、通常は2〜3個のフライト中のフレームしかありません。これをコードの最上部で定義します：

```cpp
constexpr uint32_t maxFramesInFlight{ 2 };
```

そして、CPUとGPUで共有されるすべてのリソースの次元設定にそれを使用します：

```cpp
std::array<ShaderDataBuffer, maxFramesInFlight> shaderDataBuffers;
std::array<VkCommandBuffer, maxFramesInFlight> commandBuffers;
```

!!! Note

	フライト中のフレームの概念は、CPUとGPUで共有されるリソースにのみ適用されます。GPUのみで使用されるリソースを増やす必要はありません。これはイメージなどに適用されます。

## シェーダーデータバッファー

また、[シェーダー](#the-shader)にCPU側から変更できる値（例えばユーザー入力から）を渡したいと考えます。そのために、CPUが書き込み、GPUが読み取ることができるバッファーを作成します。これらのバッファー内のデータは、ドローコールのすべてのシェーダー呼び出しで一定（均一）です。これはGPUにとって重要な保証です。

渡したいデータは単一の構造体に保存され、連続してレイアウトされるため、一致するGPU構造体に簡単にコピーできます：

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

	CPU側とGPU側で構造体レイアウトを一致させることが重要です。使用するデータ型と配置によっては、レイアウトは同じに見えるかもしれませんが、シェーディング言語が構造体メンバーを整列させる方法により、実際には異なります。これを回避する方法の1つは、構造体を手動で整列またはパディングする以外に、Vulkanの[VK_EXT_scalar_block_layout](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_scalar_block_layout.html)または対応するVulkan 1.2コア機能（両方ともオプション）を使用することです。

古いVulkanバージョンを使用する場合、ディスクリプタに対処する必要があります。これはVulkanの基本的ですが、部分的に制限があり、管理が難しい部分です。

しかし、Vulkan 1.3の[バッファーデバイスアドレス](https://docs.vulkan.org/guide/latest/buffer_device_address.html)機能を使用すると、（バッファー用の）ディスクリプタを取り除くことができます。ディスクリプタを介してアクセスするのではなく、シェーダーでポインタ構文を使用してバッファーのアドレスを介してアクセスできます。これにより、理解しやすくなり、結合が削減され、必要なコードが少なくなります。

[前の章](#cpu-and-gpu-parallelism)で述べたように、フライト中のフレームの最大数ごとに1つのシェーダーデータバッファーを作成します。そうすることで、CPUが別のバッファーから読み取っている間に、GPUが1つのバッファーを更新できます。これにより、GPUがまだ読み取っている間にCPUが値の更新を開始する読み取り/書き込みの危険に遭遇しないことが保証されます：

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

これらのバッファーの作成は、メッシュの頂点/インデックスバッファーの作成と似ています。作成情報構造体は、デバイスアドレス(`VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT`)を介してこのバッファーにアクセスしたいことを示しています。バッファーサイズはCPUデータ構造体のサイズと（少なくとも）一致する必要があります。再びVMAを使用して割り当てを処理し、頂点/インデックスバッファーと同じフラグを使用して、CPUとGPUの両方からアクセス可能なバッファーを取得します。`VMA_ALLOCATION_CREATE_MAPPED_BIT`フラグを使用すると、バッファーが永続的にマップされ、`VmaAllocationInfo`構造体でバッファーへのポインタが提供されます。古いAPIとは異なり、これはVulkanで完全に問題なく、後でバッファーを更新しやすくなります。バッファー（メモリ）への永続的なポインタを保持できるためです。

!!! Tip

	より大きな静的バッファーとは異なり、シェーダーに少量のデータを渡すバッファーはGPUのVRAMに保存する必要はありません。GPU用のそのようなメモリタイプをVMAに要求しますが、CPU側メモリにフォールバックしても問題ありません。

```cpp
	VkBufferDeviceAddressInfo uBufferBdaInfo{
		.sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO,
		.buffer = shaderDataBuffers[i].buffer
	};
	shaderDataBuffers[i].deviceAddress = vkGetBufferDeviceAddress(device, &uBufferBdaInfo);
}
```

シェーダーでバッファーにアクセスできるようにするために、デバイスアドレスを取得し、後でアクセスできるように保存します。

## 同期オブジェクト

Vulkanが非常に明示的なもう1つの領域は[同期](https://docs.vulkan.org/spec/latest/chapters/synchronization.html)です。OpenGLなどの他のAPIはこれを暗黙的に行っていました。しかし、ここでは、GPUリソースへのアクセスが適切に保護されていることを確認する必要があります。これにより、例えばGPUがまだ使用しているメモリへの書き込みをCPUが開始するなどの読み取り/書き込みの危険を回避できます。これはCPUでのマルチスレッド処理に似ていますが、CPUとGPUの間で、およびGPU自体で動作させる必要があるため、より複雑です。

!!! Warning

	Vulkanでの同期を正しく行うのは非常に難しい場合があります。特に、間違ったまたは欠落した同期は、すべてのGPUまたはすべての状況で表示されない可能性があるためです。低フレームレートやモバイルデバイスでのみ表示される場合があります。[検証レイヤー](#validation-layers)には、同期検証プリセットを使用してこれをチェックする方法が含まれています。時々有効にして、報告される危険をチェックすることをお勧めします。

このチュートリアルでは、同期の様々な手段を使用します：

* [フェンス](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-fences)は、GPUからCPUへの作業完了を通知するために使用されます。GPUとCPUの両方で使用されるリソースがCPUで変更可能であることを確認する必要がある場合に使用します。
* [バイナリセマフォ](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-semaphores)は、GPU側（のみ）でのリソースアクセスを制御するために使用されます。表示などの適切な順序を確保するために使用します。
* [パイプラインバリア](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-pipeline-barriers)は、GPUキュー内のリソースアクセスを制御するために使用されます。イメージのレイアウト遷移に使用します。

フェンスとバイナリセマフォは作成して保存する必要があるオブジェクトですが、バリアはコマンドとして発行され、後で説明します：

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

これらのオブジェクトを作成するためのオプションは多くありません。`VK_FENCE_CREATE_SIGNALED_BIT`フラグを設定することにより、フェンスはシグナル状態で作成されます。そうしないと、そのようなフェンスの最初の待機はタイムアウトになります。[フライト中のフレーム](#cpu-and-gpu-parallelism)ごとに1つのフェンスが必要で、GPUとCPU間で同期します。表示を通知するために使用されるセマフォについても同様です。レンダリングを通知するために使用されるセマフォの数は、スワップチェーンのイメージの数と一致する必要があります。その理由は後で[コマンドバッファーの送信](#submit-command-buffer)で説明します。

!!! Tip

	より複雑な同期設定の場合、[タイムラインセマフォ](https://www.khronos.org/blog/vulkan-timeline-semaphores)は冗長さを軽減するのに役立ちます。これらはカウンター値を持つセマフォタイプを追加し、増加して待機でき、CPUからもクエリしてフェンスを置換できます。

## コマンドバッファー

OpenGLなどの古いAPIとは異なり、VulkanではGPUに任意にコマンドを発行できません。代わりに、これらを[コマンドバッファー](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html)に記録し、[キュー](#queues)に送信する必要があります。

これにより、アプリケーションの観点からは少し複雑になりますが、ドライバが最適化するのに役立ち、アプリケーションが別個のスレッドでコマンドバッファーを記録できるようになります。これもまた、VulkanがCPUとGPUリソースをより適切に利用できるようにする領域の1つです。

コマンドバッファーは[コマンドプール](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandPool.html)から割り当てる必要があり、これはドライバが割り当てを最適化するのに役立つオブジェクトです：

```cpp
VkCommandPoolCreateInfo commandPoolCI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
	.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
	.queueFamilyIndex = queueFamily
};
chk(vkCreateCommandPool(device, &commandPoolCI, nullptr, &commandPool));
```

[`VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandPoolCreateFlagBits.html)フラグは、[記録する際](#record-command-buffer)にコマンドバッファーを暗黙的にリセットできるようにします。また、このプールから割り当てられたコマンドバッファーが送信されるキューファミリーを指定する必要があります。

!!! Tip

	より複雑なアプリケーションでは、複数のコマンドプールを持つことは珍しくありません。作成は安価で、複数のスレッドからコマンドバッファーを記録する場合は、スレッドごとにそのようなプールが必要です。

コマンドバッファーはCPUで記録され、GPUで実行されるため、最大[フライト中のフレーム](#cpu-and-gpu-parallelism)ごとに1つ作成します：

```cpp
VkCommandBufferAllocateInfo cbAllocCI{
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
	.commandPool = commandPool,
	.commandBufferCount = maxFramesInFlight
};
chk(vkAllocateCommandBuffers(device, &cbAllocCI, commandBuffers.data()));
```

[vkAllocateCommandBuffers](https://docs.vulkan.org/refpages/latest/refpages/source/vkAllocateCommandBuffers.html)への呼び出しは、作成したプールから`commandBufferCount`個のコマンドバッファーを割り当てます。

## テクスチャの読み込み

次に、3Dモデルのレンダリングに使用されるテクスチャをロードします。Vulkanでは、これらはイメージであり、スワップチェーンや深度イメージと同じです。GPUの観点から、イメージはバッファーよりも複雑であり、これはGPUにアップロードする際の冗長さに反映されています。

イメージフォーマットは多数ありますが、Khronosによる[KTX](https://www.khronos.org/ktx/)コンテナフォーマットを使用します。JPEGやPNGなどの形式とは異なり、ネイティブGPU形式でイメージを保存するため、解凍や変換なしで直接アップロードできます。また、ミップマップ、3Dテクスチャ、キューブマップなどのGPU固有の機能もサポートしています。KTXイメージファイルを作成するツールの1つは[PVRTexTool](https://developer.imaginationtech.com/solutions/pvrtextool/)です。

そのライブラリの助けを借りて、ディスクからそのようなファイルをロードするのは簡単です：

```cpp
for (auto i = 0; i < textures.size(); i++) {
	ktxTexture* ktxTexture{ nullptr };
	std::string filename = "assets/suzanne" + std::to_string(i) + ".ktx";
	ktxTexture_CreateFromNamedFile("assets/suzanne.ktx", KTX_TEXTURE_CREATE_LOAD_IMAGE_DATA_BIT, &ktxTexture);
	...
```

!!! Warning

	ロードするテクスチャは、アルファチャンネルを使用しなくても、チャンネルあたり8ビットのRGBAフォーマットを使用します。メモリを節約するためにRGBを使用したくなるかもしれませんが、RGBは広くサポートされていません。OpenGLでそのようなフォーマットを使用した場合、ドライバはしばしば秘密裏にそれらをRGBAに変換していました。Vulkanでは、サポートされていないフォーマットを使用しようとすると、単に失敗します。

イメージ（オブジェクト）の作成は、[深度アタッチメント](#depth-attachment)を作成した方法と非常に似ています：

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

フォーマットは`ktxTexture_GetVkFormat`を使用してテクスチャから読み取られ、幅、高さ、および[ミップレベル](https://docs.vulkan.org/spec/latest/chapters/textures.html#textures-level-of-detail-operation)の数もそこから来ます。目的の`usage`の組み合わせは、ディスクからロードしたデータをこのイメージ(`VK_IMAGE_USAGE_TRANSFER_DST_BIT`)に転送し、（後で）シェーダーでサンプリングしたい(`VK_IMAGE_USAGE_SAMPLED_BIT`)ことを意味します。再びVK_IMAGE_LAYOUT_UNDEFINEDを使用します。これはこの場合で許可される唯一のものです（許可される唯一の他のフォーマットはVK_IMAGE_LAYOUT_PREINITIALIZEDですが、これは線形タイリングされたイメージでのみ機能します）。再び`vmaCreateImage`を使用してイメージを作成し、`VMA_MEMORY_USAGE_AUTO`は最適なメモリタイプ（GPU VRAM）を取得することを確認します。

また、イメージ（テクスチャ）がアクセスされるビューを作成します。この場合、すべてのミップレベルを含むイメージ全体にアクセスしたいと考えます：

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

空のイメージが作成されたので、データをアップロードする時です。バッファーとは異なり、イメージにデータを単純にmemcpyすることはできません。これは[最適タイリング](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageTiling.html)がテクセルをハードウェア固有のレイアウトで保存し、それに変換する方法がないためです。代わりに、データをコピーする中間バッファーを作成し、GPUにコマンドを発行してそのバッファーをイメージにコピーし、その変換を行う必要があります。

そのバッファーを作成することは、[シェーダーデータバッファー](#shader-data-buffers)を作成することと非常によく似ていますが、いくつかの小さな違いがあります：

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

このバッファーはバッファーからイメージへのコピーの一時的なソースとして使用されるため、必要なフラグは[`VK_BUFFER_USAGE_TRANSFER_SRC_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html)だけです。割り当ては再びVMAによって処理されます。

バッファーがマップ可能ビットで作成されたため、イメージデータをそのバッファーに入れることは再び単純な`memcpy`の問題です：

```cpp
memcpy(imgSrcAllocInfo.pMappedData, ktxTexture->pData, ktxTexture->dataSize);
```

次に、そのバッファーからGPU上の最適タイリングされたイメージにイメージデータをコピーする必要があります。そのために、コマンドバッファーを作成する必要があります。それらがどのように機能するかについては[後で](#record-command-buffer)詳しく説明します。また、コマンドバッファーの実行が完了するのを待つために使用されるフェンスを作成します：

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

次に、イメージデータを目的地に取得するために必要なコマンドの記録を開始できます：

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

最初は少し圧倒されるかもしれませんが、簡単に説明できます。以前に、テクセルがGPUによる最適なアクセスのためにハードウェア固有のレイアウトで保存される最適タイリングされたイメージについて学びました。その[レイアウト](https://docs.vulkan.org/spec/latest/chapters/resources.html#resources-image-layouts)はまた、イメージでどのような操作が可能かを定義します。そのため、イメージで次に行いたいことに応じてそのレイアウトを変更する必要があります。これは[vkCmdPipelineBarrier2](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdPipelineBarrier2.html)によって発行されるパイプラインバリアを介して行われます。最初のバリアは、テクスチャイメージのすべてのミップレベルを初期の未定義レイアウトから、それにデータを転送できるレイアウト(`VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL`)に遷移させます。次に、一時バッファーからイメージにすべてのミップレベルを[vkCmdCopyBufferToImage](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdCopyBufferToImage.html)を使用してコピーします。最後に、ミップレベルを転送先から、シェーダーで読み取れるレイアウト(`VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL`)に遷移させます。このコマンドバッファーをグラフィックスキューに送信すると、これらすべてのコマンドが実行されます。コマンドバッファーの送信については[後で](#submit-command-buffer)詳しく説明します。

!!! Tip

	これを容易にする拡張機能には、コマンドバッファーを使用せずにCPUから直接イメージデータをコピーすることを可能にする[VK_EXT_host_image_copy](https://www.khronos.org/blog/copying-images-on-the-host-in-vulkan)と、イメージレイアウトを簡素化する[VK_KHR_unified_image_layouts](https://www.khronos.org/blog/so-long-image-layouts-simplifying-vulkan-synchronisation)があります。これらはまだ広くサポートされていませんが、Vulkanをより使いやすくする将来の候補です。

後でシェーダーでこれらのテクスチャをサンプリングし、そこで使用されるサンプリングパラメータはサンプラーオブジェクトによって定義されます。滑らかな線形フィルタリングが必要で、ブラーとエイリアシングを減らすために[異方性フィルタ](https://docs.vulkan.org/spec/latest/chapters/textures.html#textures-texel-anisotropic-filtering)を有効にします。また、すべてのミップレベルを使用するために最大LODを設定します：

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

最後に、クリーンアップし、そのテクスチャのディスクリプタ関連情報を保存して後で使用します：

```cpp
ktxTexture_Destroy(ktxTexture);
textureDescriptors.push_back({
    .sampler = textures[i].sampler,
    .imageView = textures[i].view,
    .imageLayout = VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL
});
```

テクスチャイメージをアップロードし、それらを正しいレイアウトに配置し、それらをサンプリングする方法を把握したので、シェーダーでGPUがそれらにアクセスする方法が必要です。GPUの観点から、イメージはバッファーよりも複雑であり、GPUはそれらがどのように見えるか、どのようにアクセスされるかについてより多くの情報を必要とします。これが[ディスクリプタ](https://docs.vulkan.org/spec/latest/chapters/descriptorsets.html)が必要な場所であり、シェーダーリソースを表す（したがって名前が付いている）ハンドルです。

以前のVulkanバージョンでは、バッファーにもそれらを使用する必要がありましたが、[シェーダーデータバッファー](#shader-data-buffers)の章で述べたように、バッファーデバイスアドレスはそれを行う必要から私たちを救います。イメージにはまだそれに相当する使いやすく広く利用可能なものはありません。

ディスクリプタ処理はまだ最も冗長な部分の1つですが、[ディスクリプタインデックス](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html)を使用すると、大幅に簡素化され、拡張しやすくなります。この機能により、「バインドレス」設定を採用し、すべてのテクスチャを1つの大きな配列に入れ、[シェーダー](#the-shader)でインデックスを付けてアクセスし、各テクスチャごとにディスクリプタセットを作成してバインドする必要がなくなります。これがどのように機能するかを示すために、複数のテクスチャをロードします。このアプローチは、使用するテクスチャの数（GPUがサポートする制限内）に関係なく拡張します。

まず、ディスクリプタセットレイアウトの形式でアプリケーションとシェーダー間のインターフェースを定義します：

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

イメージ用のディスクリプタのみを使用するため、単一のバインディングしかありません。[VkDescriptorSetLayoutBindingFlagsCreateInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorSetLayoutBindingFlagsCreateInfo.html)は、ディスクリプタインデックスの一部としてそのバインディングで可変数のディスクリプタを有効にするために使用され、`pNext`を介して渡されます。テクスチャイメージとサンプラー（以下を参照）を組み合わせるため、バインディングのタイプは[`VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER`](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorType.html)である必要があります。そのレイアウトにはロードしたテクスチャと同じ数のディスクリプタがあり、フラグメントシェーダーからのみアクセスする必要があるため、`stageFlags`を`VK_SHADER_STAGE_FRAGMENT_BIT`に設定します。[vkCreateDescriptorSetLayout](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateDescriptorSetLayout.html)を呼び出すと、この構成でディスクリプタセットレイアウトが作成されます。これをディスクリプタを割り当てるために、および[パイプラインの作成](#graphics-pipeline)でシェーダーインターフェースを定義するために必要です。

!!! Tip

	イメージとサンプラーを分離するシナリオがあります。例えば、多くのイメージがあり、それぞれにサンプラーを保存してメモリを浪費したくない場合や、動的に異なるサンプリングオプションを使用したい場合などです。その場合、`VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE`用と`VK_DESCRIPTOR_TYPE_SAMPLER`用の2つのプールサイズを使用します。

コマンドバッファーと同様に、ディスクリプタはディスクリプタプールから割り当てられます：

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

割り当てたいディスクリプタタイプの数をここで事前に指定する必要があります。ロードするテクスチャと同じ数の結合イメージとサンプラー用のディスクリプタが必要です。また、`maxSets`を介して割り当てたいディスクリプタセットの数（**ディスクリプタではない**）を指定する必要があります。これは1つです。ディスクリプタインデックスを使用するため、結合イメージとサンプラーの配列を使用します。また、GPUのみによってアクセスされるため、最大フライト中のフレームごとに複製する必要はありません。プールサイズを正しくすることが重要です。要求された数を超える割り当ては失敗します。

次に、そのプールからディスクリプタセットを割り当てます。ディスクリプタセットレイアウトはインターフェースを定義しますが、ディスクリプタは実際のディスクリプタデータを含みます。レイアウトとセットが分割されている理由は、レイアウトを混合し、異なるディスクリプタセットで再利用できるためです。

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

ディスクリプタセットレイアウトの作成と同様に、`pNext`で[VkDescriptorSetVariableDescriptorCountAllocateInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorSetVariableDescriptorCountAllocateInfo.html)を介してディスクリプタインデックス設定を割り当てに渡す必要があります。

[vkAllocateDescriptorSets](https://docs.vulkan.org/refpages/latest/refpages/source/vkAllocateDescriptorSets.html)によって割り当てられたディスクリプタセットは大部分が初期化されておらず、シェーダーでアクセスする前に実際のデータでバックアップする必要があります：

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

[VkDescriptorImageInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorImageInfo.html)は、`pImageInfo`でサンプラーと組み合わされた上記でロードしたテクスチャのディスクリプタの配列を参照します。[vkUpdateDescriptorSets](https://docs.vulkan.org/refpages/latest/refpages/source/vkUpdateDescriptorSets.html)を呼び出すと、その情報がディスクリプタセットの最初の（この場合は唯一の）バインディングスロットに配置されます。

## シェーダーの読み込み

以前述べたように、GPUで実行されるシェーダーを記述するために[Slang言語](https://github.com/shader-slang)を使用します。Vulkanはそのような言語（またはGLSLやHLSL）で記述されたシェーダーを直接ロードできません。それらはSPIR-V中間形式であることを期待しています。そのために、まずSlangからSPIR-Vにコンパイルする必要があります。これには2つのアプローチがあります。Slangのコマンドラインコンパイラを使用してオフラインでコンパイルするか、Slangのライブラリを使用して実行時にコンパイルします。

後者を採用します。これにより、シェーダーの更新が少し容易になります。オフラインコンパイルを使用する場合、シェーダーを変更するたびに再コンパイルするか、ビルドシステムにそれを行わせる方法を見つける必要があります。実行時コンパイルを使用すると、コードを実行するたびに常に最新のシェーダーバージョンを使用できます。

Slangシェーダーをコンパイルするために、まずグローバルSlangセッションを作成します。これはアプリケーションとSlangライブラリ間の接続です：

```cpp
slang::createGlobalSession(slangGlobalSession.writeRef());
```

次に、コンパイルスコープを定義するセッションを作成します。SPIR-Vにコンパイルしたいので、ターゲット`format`を`SLANG_SPIRV`に設定します。シェーダー機能のベースラインとして[SPIR-V 1.4](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_spirv_1_4.html)を使用します。これはVulkan 1.2からコアになっているため、この場合はサポートが保証されています。また、後で行列を構築するために使用するGLMライブラリのレイアウトと一致するように、`defaultMatrixLayoutMode`を列メジャーレイアウトに変更します：

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

`createSession`によって作成されたセッションは、SlangシェーダーのSPIR-V表現を取得するために使用できます。そのために、まず`loadModuleFromSource`を使用してファイルからテキストシェーダーをロードし、次に`getTargetCode`を使用してシェーダーのすべてのエントリポイントをSPIR-Vにコンパイルします：

```cpp
Slang::ComPtr<slang::IModule> slangModule{
    slangSession->loadModuleFromSource("triangle", "assets/shader.slang", nullptr, nullptr)
};
Slang::ComPtr<ISlangBlob> spirv;
slangModule->getTargetCode(0, spirv.writeRef());
```

グラフィックスパイプライン（以下を参照）でシェーダーを使用するために、シェーダーモジュールを作成する必要があります。これらはコンパイルされたSPIR-Vシェーダーのコンテナです。そのようなモジュールを作成するには、SlangによってコンパイルされたSPIR-Vを[`vkCreateShaderModule`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateShaderModule.html)に渡します：

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

	[Vulkan 1.4からコアになった](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_maintenance5.html)[VK_KHR_maintenance5](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_maintenance5.html)拡張機能は、シェーダーモジュールを非推奨にしました。これにより、`VkShaderModuleCreateInfo`をパイプラインのシェーダーステージ作成情報に直接渡すことができます。

## シェーダー

シェーディング言語はCPUプログラミング言語ほど強力ではありませんが、複雑なシナリオを処理できます。私たちのシェーダーは意図的にシンプルに保たれています：

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
    // 照明に必要なビューベクトルを計算
    float4 fragPos = mul(mul(shaderData->view, modelMat), float4(input.Pos.xyz, 1.0));
    output.LightVec = shaderData->lightPos.xyz - fragPos.xyz;
    output.ViewVec = -fragPos.xyz;
    return output;
}

[shader("fragment")]
float4 main(VSOutput input) {
    // Phong照明
    float3 N = normalize(input.Normal);
    float3 L = normalize(input.LightVec);
    float3 V = normalize(input.ViewVec);
    float3 R = reflect(-L, N);
    float3 diffuse = max(dot(N, L), 0.0025);
    float3 specular = pow(max(dot(R, V), 0.0), 16.0) * 0.75;
    // テクスチャからサンプリング
    float3 color = textures[NonUniformResourceIndex(input.InstanceIndex)].Sample(input.UV).rgb * input.Factor;
    return float4(diffuse * color.rgb + specular, 1.0);
}
```

!!! Tip

	Slangでは、すべてのシェーダーステージを単一のファイルに入れることができます。これにより、シェーダーインターフェースを複製したり、それを共有インクルードに配置したりする必要がなくなります。また、シェーダーを読みやすく（編集しやすく）なります。

これには2つのシェーディングステージが含まれ、異なるステージで使用される構造体を定義することから始まります。`ShaderData`構造体は、[CPU側](#shader-data-buffers)で定義されたシェーダーデータ構造体のレイアウトと一致します。

最初は[`[shader("vertex")]`属性でマークされた頂点シェーダーです。これは、[グラフィックスパイプライン](#graphics-pipeline)からの頂点レイアウトに従って定義された`VSInput`としての頂点を受け取ります。頂点シェーダーは、[描画](#record-command-buffer)される各頂点で呼び出されます。バッファーデバイスアドレスを使用するため、UBOをポインタとして渡してアクセスします。3Dモデルの複数のインスタンスを描画し、各インスタンスに異なる行列を使用したいと考え、組み込みの`SV_VulkanInstanceID`システム値を使用してモデル行列にインデックスを付けます。また、選択したモデルを強調表示したいと考え、現在のインスタンスがその選択と一致する場合、フラグメントシェーダーに異なる色係数を渡します。

2番目は[`[shader("fragment")]`属性でマークされたフラグメントシェーダーです。まず、頂点シェーダーから渡された値を使用して基本的な照明を[Phong反射モデル](https://en.wikipedia.org/wiki/Phong_reflection_model)で計算します。次に、ディスクリプタインデックスを示すために、インスタンスインデックスを使用してテクスチャの配列(`Sampler2D textures[]`)から読み取り、最後にそれを照明計算と組み合わせます。これは現在のカラーアタッチメントに書き込まれます。

## グラフィックスパイプライン

VulkanがOpenGLと大きく異なるもう1つの領域は状態管理です。OpenGLは巨大な状態マシンであり、その状態はいつでも変更できました。これにより、ドライバが最適化することが困難でした。Vulkanはパイプライン状態オブジェクトを導入することでこれを根本的に変更しました。これらは「コンパイルされた」パイプラインオブジェクトでパイプライン状態の完全なセットを提供し、ドライバがそれらを最適化する機会を与えます。これらのオブジェクトはまた、例えば別個のスレッドでパイプラインオブジェクトを作成することを可能にします。異なるパイプライン状態が必要な場合は、新しいパイプライン状態オブジェクトを作成する必要があります。

!!! Note

	Vulkanには動的にできる状態が*いくつか*あります。主にビューポートとシザーステージ設定などの基本的な状態です。それらが動的であることはドライバにとって問題ではありません。追加の状態を動的にするいくつかの拡張機能がありますが、ここでは使用しません。

Vulkanは、ラスタライズ、計算、レイトレーシングなどのユースケース固有の[パイプラインタイプ](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineBindPoint.html)をサポートしています。そのため、パイプラインの設定は達成したい内容によって異なります。この場合、それはグラフィックス（別名[ラスタライズ](https://en.wikipedia.org/wiki/Rasterisation)）であるため、グラフィックスパイプラインを作成します。

まず、パイプラインレイアウトを作成します。これはパイプラインとシェーダー間のインターフェースを定義します。パイプラインレイアウトは別個のオブジェクトであり、他のパイプラインで使用するために混合して一致させることができます：

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

[`pushConstantRange`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPushConstantRange.html)は、バッファーを介さずにシェーダーに直接プッシュできる値の範囲を定義します。これらを使用して、シェーダーデータバッファーバッファーへのポインタを渡します（後で詳しく説明します）。ディスクリプタセットレイアウト(`pSetLayouts`)はシェーダーリソースへのインターフェースを定義します。この場合、テクスチャイメージディスクリプタを渡すためのレイアウトが1つだけです。[`vkCreatePipelineLayout`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCreatePipelineLayout.html)を呼び出すと、パイプラインで使用できるパイプラインレイアウトが作成されます。

パイプラインとシェーダー間のインターフェースのもう1つの部分は、頂点データのレイアウトです。[メッシュの読み込みの章](#loading-meshes)で基本的な頂点構造体を定義しましたが、それをVulkan用語で指定する必要があります。単一の頂点バッファーを使用するため、1つの[頂点バインディングポイント](https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputBindingDescription.html)が必要です。`stride`は頂点構造体のサイズと一致します。頂点はメモリ内で直接隣接して保存されるためです。`inputRate`は頂点ごとであり、読み取られる各頂点でデータポインタが進むことを意味します：

```cpp
VkVertexInputBindingDescription vertexBinding{
	 .binding = 0,
	 .stride = sizeof(Vertex),
	 .inputRate = VK_VERTEX_INPUT_RATE_VERTEX
};
```

次に、位置、法線、テクスチャ座標の[頂点属性](https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputAttributeDescription.html)がメモリでどのようにレイアウトされるかを指定します。これはCPU側の頂点構造体と正確に一致します：

```cpp
std::vector<VkVertexInputAttributeDescription> vertexAttributes{
	{ .location = 0, .binding = 0, .format = VK_FORMAT_R32G32B32_SFLOAT },
	{ .location = 1, .binding = 0, .format = VK_FORMAT_R32G32B32_SFLOAT, .offset = offsetof(Vertex, normal) },
	{ .location = 2, .binding = 0, .format = VK_FORMAT_R32G32_SFLOAT, .offset = offsetof(Vertex, uv) },
};
```
!!! Tip

	シェーダーで頂点にアクセスするもう1つのオプションは、バッファーデバイスアドレスです。そうすると、従来の頂点属性をスキップし、シェーダーでポインタを使用して手動でそれらをフェッチできます。これは「頂点プル」と呼ばれます。一部のデバイスでは遅くなる可能性があるため、従来の方法を使用します。

次に、パイプラインを作成するために必要な多くの`VkPipeline*CreateInfo`構造体を埋め始めます。これらすべてを詳細には説明しません。[仕様](https://docs.vulkan.org/refpages/latest/refpages/source/VkGraphicsPipelineCreateInfo.html)で読むことができます。それらはすべて少し似ており、パイプラインの特定の部分を記述します。

最初は、上記で定義した[頂点入力](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineVertexInputStateCreateInfo.html)のパイプライン状態です：

```cpp
VkPipelineVertexInputStateCreateInfo vertexInputState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
	.vertexBindingDescriptionCount = 1,
	.pVertexBindingDescriptions = &vertexBinding,
	.vertexAttributeDescriptionCount = static_cast<uint32_t>(vertexAttributes.size()),
	.pVertexAttributeDescriptions = vertexAttributes.data(),
};
```

頂点データに直接接続されるもう1つの構造体は[入力アセンブリ状態](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineInputAssemblyStateCreateInfo.html)です。これは[プリミティブ](https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html)がどのようにアセンブルされるかを定義します。分離された三角形のリストをレンダリングしたいので、[`VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST`](https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html)を使用します：

```cpp
VkPipelineInputAssemblyStateCreateInfo inputAssemblyState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
	.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
};
```

パイプラインの重要な部分の1つは、使用したい[シェーダー](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineShaderStageCreateInfo.html)と、それらがマップされるパイプラインステージです。シェーダーのセットが1つしかないため、パイプラインが1つだけで済みます。Slangのおかげで、すべてのステージを単一のシェーダーモジュールで取得できます：

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

	異なるシェーダー（またはシェーダーの組み合わせ）を使用したい場合、複数のパイプラインを作成する必要があります。[VK_EXT_shader_objects](https://www.khronos.org/blog/you-can-use-vulkan-without-pipelines-today)は、これらのシェーダーステージを別個のオブジェクトにし、APIのこの部分に柔軟性を追加します。

次に、[ビューポート状態](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineViewportStateCreateInfo.html)を設定します。1つのビューポートと1つのシザーを使用し、それらを動的状態にして、それらのいずれかが変更された場合（例えばウィンドウのサイズ変更時）にパイプラインを再作成する必要がないようにします。これはVulkan 1.0からあった動的状態の1つです：

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

[深度バッファリング](#depth-attachment)を使用したいので、深度テストと書き込みの両方を有効にし、ビューアに近いフラグメントが深度テストに合格するように比較演算を設定して、[深度/ステンシル状態](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineDepthStencilStateCreateInfo.html)を設定します：

```cpp
VkPipelineDepthStencilStateCreateInfo depthStencilState{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
	.depthTestEnable = VK_TRUE,
	.depthWriteEnable = VK_TRUE,
	.depthCompareOp = VK_COMPARE_OP_LESS_OR_EQUAL
};
```

次の状態は、厄介なレンダーパスオブジェクトの代わりにダイナミックレンダリングを使用することをパイプラインに伝えます。レンダーパスとは異なり、これを設定するのは非常に簡単であり、パイプラインとレンダーパス間の緊密な結合も削除されます。ダイナミックレンダリングの場合、使用するアタッチメントの数とフォーマット（後で）を指定するだけで済みます：

```cpp
VkPipelineRenderingCreateInfo renderingCI{
	.sType = VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO,
	.colorAttachmentCount = 1,
	.pColorAttachmentFormats = &imageFormat,
	.depthAttachmentFormat = depthFormat
};
```

!!! Note

	この機能はVulkanのライフの後半で追加されたため、パイプライン作成情報には専用のメンバーがありません。代わりに、これを`pNext`（以下）に渡します

次の状態は使用しませんが、指定する必要があり、合理的なデフォルト値を持つ必要があります。したがって、[ブレンディング](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineColorBlendStateCreateInfo.html)、[ラスタライズ](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineRasterizationStateCreateInfo.html)、および[マルチサンプリング](https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineMultisampleStateCreateInfo.html)をデフォルト値に設定します：

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

関連するすべてのパイプライン状態作成構造体が適切に設定されたので、それらを配線してグラフィックスパイプラインを最終的に作成します：

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

[`vkCreateGraphicsPipelines`](https://docs.vulkan.org/refpages/latest/refpages/source/vkCreateGraphicsPipelines.html)への呼び出しが成功すると、グラフィックスパイプラインがレンダリングに使用できるようになります。

## レンダリングループ

ここまで来るにはかなり努力が必要でしたが、これで実際に画面に何かを「描画」する準備ができました。以前と同様に、これはVulkanでは明示的であり、間接的でもあります。現在、画面に何かを表示することは、初期のコンピュータグラフィックスが機能した方法と比較して複雑な問題です。特に、多くの異なるプラットフォームとデバイスをサポートする必要があるAPIでは。

これにより、レンダリングループに到達します。ここで、ユーザー入力を受け取り、シーンをレンダリングし、シェーダー値を更新し、これらすべてがCPUとGPU間、およびGPU自体で適切に同期されるようにします：

```cpp
uint64_t lastTime{ SDL_GetTicks() };
bool quit{ false };
while (!quit) {
	// Wait on fence
	// Acquire next image
	// Update shader data
	// Record command buffer
	// Submit command buffer
	// Present image
	// Poll events
}
```

ループはウィンドウが開いている限り実行されます。SDLはまた、フレームレートに依存しない計算のために経過時間を測定するために使用する正確な[タイミング関数](https://wiki.libsdl.org/SDL3/SDL_GetTicks)も提供します。

ループ内で多くのことが起こるため、各部分を個別に見ていきます。

### フェンスでの待機

[CPUとGPUの並列処理](#cpu-and-gpu-parallelism)で述べたように、CPUとGPUの作業を重ねることができる領域の1つはコマンドバッファーの記録です。GPUがまだ前の作業でビジー状態の間、CPUですでに次のコマンドバッファーの記録を開始したいと考えます。

そのために、GPUが作業した最後のフレームのフェンスが実行を完了するのを待機します：

```cpp
chk(vkWaitForFences(device, 1, &fences[frameIndex], true, UINT64_MAX));
chk(vkResetFences(device, 1, &fences[frameIndex]));
```

[vkWaitForFences](https://docs.vulkan.org/refpages/latest/refpages/source/vkWaitForFences.html)への呼び出しは、GPUがそのフェンスで送信されたすべての作業の完了を通知するまでCPUで待機します。意図的に大きなタイムアウト値`UINT64_MAX`を使用します。フェンスはまだシグナル状態にあるため、次の送信のために[リセット](https://docs.vulkan.org/refpages/latest/refpages/source/vkResetFences.html)する必要もあります。

!!! Note

	グラフィックス操作がどのくらいかかってもよいという要件はないため、基本的にタイムアウトを気にしません。特に複雑なタスクは実行せず、フェンスは通常数ミリ秒以内にシグナルされます。また、ほとんどのオペレーティングシステムは、グラフィックスタスクが長すぎる場合にGPUをリセットする機能を実装しています。

### 次のイメージの取得

[スワップチェーンイメージ](#swapchain)を直接制御できないため、このフレームで使用する次のインデックスをスワップチェーンに「要求」（取得）する必要があります：

```cpp
chkSwapchain(vkAcquireNextImageKHR(device, swapchain, UINT64_MAX, presentSemaphores[frameIndex], VK_NULL_HANDLE, &imageIndex));
```

[vkAcquireNextImageKHR](https://docs.vulkan.org/refpages/latest/refpages/source/vkAcquireNextImageKHR.html)によって返されるイメージインデックスを使用してスワップチェーンイメージにアクセスすることが重要です。これはイメージが連続した順序で取得される保証がないためです。これが2つのインデックスがある理由の1つです。

また、この関数に[セマフォ](#synchronization-objects)を渡します。これは後でコマンドバッファーの送信時に使用されます。

!!! Note

	表示に関連する呼び出しの戻り値をチェックするために、`chk`関数のバリエーションを使用しています。これは、サーフェスがスワップチェーンと互換性がなくなったときに返される[VK_ERROR_OUT_OF_DATE_KHR](https://docs.vulkan.org/spec/latest/chapters/fundamentals.html#VkResult)によるものです。これは、例えばディスプレイの向きが変更された場合など、特定のプラットフォームで発生する可能性があります。これらの場合にアプリケーションが終了しないように、`chkSwapchain`でこのエラーを明示的に処理します。終了する代わりに、次のフレームのためにスワップチェーンを再作成します。

### シェーダーデータの更新

次のフレームが最新のユーザー入力を使用するようにしたいと考えます。フェンスを待機した後、これを安全に行うことができます。そのために、glmを使用して現在のデータから行列を更新します：

```cpp
shaderData.projection = glm::perspective(glm::radians(45.0f), (float)window.getSize().x / (float)window.getSize().y, 0.1f, 32.0f);
shaderData.view = glm::translate(glm::mat4(1.0f), camPos);
for (auto i = 0; i < 3; i++) {
	auto instancePos = glm::vec3((float)(i - 1) * 3.0f, 0.0f, 0.0f);
	shaderData.model[i] = glm::translate(glm::mat4(1.0f), instancePos) * glm::mat4_cast(glm::quat(objectRotations[i]));
}
```

シェーダーデータバッファーの永続的にマップされたポインタへの単純な`memcpy`で、これをGPU（したがってシェーダー）で使用可能にするのに十分です：

```cpp
memcpy(shaderDataBuffers[frameIndex].allocationInfo.pMappedData, &shaderData, sizeof(ShaderData));
```

これは[シェーダーデータバッファー](#shader-data-buffers)がCPU（書き込み用）とGPU（読み取り用）の両方からアクセス可能なメモリタイプに保存されているため機能します。前のフェンス同期により、GPUがまだ読み取っている間にCPUがそのシェーダーデータバッファーへの書き込みを開始しないことも保証されます。

### コマンドバッファーの記録

これで実際のGPU作業項目の記録を開始できます。そのために必要なものの多くは以前に説明したため、コードが多くなりますが、簡単に従うことができるはずです。[コマンドバッファー](#command-buffers)で述べたように、コマンドはVulkanでGPUに直接発行されず、コマンドバッファーに記録されます。これがまさに行うことです。単一のレンダリングフレームのコマンドを記録します。

コマンドバッファーを事前に記録し、再記録が必要なものが変更されるまで再利用したくなるかもしれません。しかし、これにより不必要に複雑になります。CPU/GPU並列処理で機能する更新ロジックを実装する必要があるためです。また、コマンドバッファーの記録は比較的速く、必要に応じて他のCPUスレッドにオフロードできるため、毎フレーム記録することは完全に問題ありません。

!!! Note

	コマンドバッファーに記録されるコマンドは`vkCmd`で始まります。これらは直接実行されず、コマンドバッファーがキュー（GPUタイムライン）に送信されたときにのみ実行されます。これもまた、これらのコマンドが結果を返さない理由を説明しています。初心者の一般的な間違いは、これらのコマンドをCPUタイムラインで即座に実行されるコマンドと混合することです。これら2つの異なるタイムラインが存在することを覚えておくことが重要です。

コマンドバッファーには従う必要がある[ライフサイクル](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html#commandbuffers-lifecycle)があります。例えば、実行可能な状態にある間はコマンドを記録できません。これは[検証レイヤー](#validation-layers)によってもチェックされ、誤って使用した場合に通知されます。

まず、コマンドバッファーを初期状態に移動する必要があります。これは[リセットすること](https://docs.vulkan.org/refpages/latest/refpages/source/vkResetCommandBuffer.html)によって行われ、以前にフェンスを待機したため、まだ保留状態ではないことが確実なので、今は安全に行うことができます：

```cpp
auto cb = commandBuffers[frameIndex];
chk(vkResetCommandBuffer(cb, 0));
```

リセットすると、コマンドバッファーの記録を開始できます：

```cpp
VkCommandBufferBeginInfo cbBI {
	.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
	.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT
};
chk(vkBeginCommandBuffer(cb, &cbBI));
```

[`VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT`](https://docs.vulkan.org/refpages/latest/refpages/source/VkCommandBufferUsageFlagBits.html)フラグは、実行後にライフサイクルが無効状態に移動する方法に影響し、ドライバによる最適化のヒントとして使用できます。[vkBeginCommandBuffer](https://docs.vulkan.org/refpages/latest/refpages/source/vkBeginCommandBuffer.html)を呼び出すと、コマンドバッファーが記録状態に移動し、実際のコマンドの記録を開始できます。

レンダリング中、色情報は現在の[スワップチェーンイメージ](#swapchain)に書き込まれ、深度情報は[深度イメージ](#depth-attachment)に書き込まれます。[テクスチャの読み込み](#loading-textures)で学んだように、最適タイリングされたイメージは意図された使用法のために正しいレイアウトにある必要があります。そのため、最初のステップは、両方のレイアウト遷移を発行することです：

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

[イメージメモリバリア](https://docs.vulkan.org/spec/latest/chapters/synchronization.html#synchronization-dependencies)はレイアウトを遷移させるだけでなく、これが正しい[パイプラインステージ](https://docs.vulkan.org/spec/latest/chapters/pipelines.html#pipelines-block-diagram)で行われるようにし、コマンドバッファー内で順序を強制します。以前使用した他の同期プリミティブと同様に、これらはGPUが例えば前のパイプラインステージがまだ読み取っている間に、あるパイプラインステージでイメージへの書き込みを開始しないようにするために必要です。これらはまた、書き込みを次のステージに表示します。`srcStageMask`は待機するパイプラインステージで、`srcAccessMask`は利用可能にする書き込みを定義します。`dstStageMask`と`dstAccessMask`はどこでどの書き込みを表示するかを定義します。

!!! Note

	利用可能と表示は同じように聞こえるかもしれませんが、そうではありません。これはCPU/GPUがどのように機能し、キャッシュとどのように対話するかによるためです。利用可能とは、将来のメモリ操作（例えばキャッシュフラッシュ）のためにデータが準備できていることを意味します。表示とは、消費ステージからの読み取りでデータが実際に見えることを意味します。

*最初のバリア*は現在のスワップチェーンイメージを、レンダリングのカラーアタッチメントとして使用できる[レイアウト](https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html)（`newLayout`）に遷移させます。同様に、*2番目のバリア*は深度イメージを、レンダリングの深度アタッチメントとして使用できるレイアウトに遷移させます。両方とも未定義レイアウト（`oldLayout`）から遷移します。これはこれらのイメージのいずれかの以前の内容を必要としないためです。

!!! Tip

	`VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL`レイアウトはVulkan 1.3のコア機能であり、すべてのタイプのアタッチメントレイアウトを単一のものに結合します。これによりイメージバリアが簡素化されます。

[vkCmdPipelineBarrier2](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdPipelineBarrier2.html)を呼び出すと、これら2つのバリアが現在のコマンドバッファーに挿入されます。

アタッチメントが正しいレイアウトになったので、それらを使用する方法を定義する時です。以前述べたように、Vulkan 1.0の複雑で厄介なレンダーパスオブジェクトの代わりに、[ダイナミックレンダリング](https://www.khronos.org/blog/streamlining-render-passes)を使用します。

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

カラーアタッチメントとして使用されるスワップチェーンイメージと、深度アタッチメントとして使用される深度イメージ用に1つの[VkRenderingAttachmentInfo](https://docs.vulkan.org/refpages/latest/refpages/source/VkRenderingAttachmentInfo.html)を設定します。両方とも`loadOp`を`VK_ATTACHMENT_LOAD_OP_CLEAR`に設定して、レンダリングパスの開始時にそれぞれの`clearValue`にクリアされます。カラーアタッチメントの`storeOp`はその内容を保持するように設定されています。画面に表示する必要があるためです。レンダリングが完了したら深度情報は必要ないため、レンダリングパス後にその内容がどうなるかは気にしません。両方のレイアウトは以前に遷移させたものと一致する必要があります。

[vkCmdBeginRendering](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdBeginRendering.html)を呼び出すと、上記のアタッチメント構成でダイナミックレンダーパスインスタンスが開始されます：

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

このレンダリングパスインスタンス内で、GPUコマンドの記録を開始できます。これらはまだGPUに発行されていないことに注意してください。現在のコマンドバッファーに記録されているだけです。

まず、[ビューポート](https://docs.vulkan.org/spec/latest/chapters/vertexpostproc.html#vertexpostproc-viewport)を設定して、レンダリング領域を定義します。これを常にウィンドウ全体にしたいと考えます。[シザー](https://docs.vulkan.org/spec/latest/chapters/fragops.html#fragops-scissor)領域についても同様です。両方とも[パイプラインの作成](#graphics-pipeline)で有効にした動的状態の一部であるため、ウィンドウのサイズ変更ごとにグラフィックスパイプラインを再作成する必要なく、コマンドバッファー内でそれらを調整できます：

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

次は、3Dオブジェクトのレンダリングに関与するリソースをバインドすることです。[グラフィックスパイプライン](#graphics-pipeline)（これには頂点シェーダーとフラグメントシェーダーも含まれます）、[テクスチャイメージ](#loading-textures)の配列用のディスクリプタセット、および[3Dメッシュ](#loading-meshes)の頂点とインデックスバッファー：

```cpp
vkCmdBindPipeline(cb, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);
VkDeviceSize vOffset{ 0 };
vkCmdBindDescriptorSets(cb, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &descriptorSetTex, 0, nullptr);
vkCmdBindVertexBuffers(cb, 0, 1, &vBuffer, &vOffset);
vkCmdBindIndexBuffer(cb, vBuffer, vBufSize, VK_INDEX_TYPE_UINT16);
```

また、[シェーダーデータバッファー](#shader-data-buffer)のデータにアクセスしたいと考えます。ディスクリプタを介する代わりにバッファーデバイスアドレスを使用することを選択したため、代わりに現在のフレームのシェーダーデータバッファーのアドレスをプッシュ定数を介してシェーダーに渡します：

```cpp
vkCmdPushConstants(cb, pipelineLayout, VK_SHADER_STAGE_VERTEX_BIT, 0, sizeof(VkDeviceAddress), &shaderDataBuffers[frameIndex].deviceAddress);
```

!!! Note

	これらの`vkCmd*`呼び出し（およびその他多くのもの）は現在のコマンドバッファー状態を設定します。これは、このコマンドバッファー内の複数のドローコールにわたって持続することを意味します。したがって、例えば同じパイプラインで異なるディスクリプタセットを使用して2番目のドローコールを発行したい場合、残りの状態を保持しながら、別のセットで`vkCmdBindDescriptorSets`を呼び出すだけで済みます。

これで*ついに*実際のドローコマンドを発行する準備ができました。ここまでの作業のおかげで、それは単一のコマンドです：

```cpp
vkCmdDrawIndexed(cb, indexCount, 3, 0, 0, 0);
```

[vkCmdDrawIndexed](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdDrawIndexed.html)へのこの呼び出しは、現在バインドされているインデックスと頂点バッファーからindexCount / 3個の三角形を描画します。また、3Dメッシュの複数のインスタンスを描画したいと考え、インスタンス数（3番目の引数）を3に設定し、これを[頂点シェーダー](#the-shader)で使用して[モデル行列](#shader-data-buffers)にインデックスを付けます。

現在、現在のレンダリングパスを[終了](https://docs.vulkan.org/refpages/latest/refpages/source/vkCmdEndRendering.html)します：

```cpp
vkCmdEndRendering(cb);
```

そして、アタッチメントとして使用した（色値を出力するために）スワップチェーンイメージを、[表示](#present-image)に必要なレイアウトに遷移させます：

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

深度アタッチメント用のバリアは必要ありません。このレンダリングパスの外ではそれを使用しないためです。

最後にコマンドバッファーの記録を[終了](https://docs.vulkan.org/refpages/latest/refpages/source/vkEndCommandBuffer.html)します：

```cpp
vkEndCommandBuffer(cb);
```

これはそれを[実行可能な状態](https://docs.vulkan.org/spec/latest/chapters/cmdbuffers.html#commandbuffers-lifecycle)に移動します。これは次のステップの要件です。

### コマンドバッファーの送信

記録したコマンドを実行するには、コマンドバッファーを一致するキューに送信する必要があります。実際のアプリケーションでは、異なるタイプの複数のキューを持つことは珍しくなく、より複雑な送信パターンもよくあります。しかし、グラフィックスコマンドのみを使用する（計算やレイトレーシングなし）ため、現在のフレームのコマンドバッファーを送信する単一のグラフィックスキューしかありません：

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

[`VkSubmitInfo`](https://docs.vulkan.org/refpages/latest/refpages/source/VkSubmitInfo.html)構造体にはいくつかの説明が必要です。特に同期に関してです。以前に、CPUとGPU間、およびGPU自体で作業を適切に同期するために必要な[同期プリミティブ](#synchronization-objects)について学びました。そしてこれがすべてまとまる場所です。

`pWaitSemaphores`のセマフォは、現在のフレームの表示が完了するまで、送信されたコマンドバッファーが実行を開始しないようにします。`pWaitDstStageMask`のパイプラインステージは、パイプラインのカラーアタッチメント出力ステージで待機が発生するようにします。したがって（理論的に）、GPUはこの前のパイプラインステージ（例えば頂点のフェッチ）で作業を開始する可能性があります。一方、`pSignalSemaphores`のシグナルセマフォは、コマンドバッファーの実行が完了するとGPUによってシグナルされるセマフォです。この組み合わせは、GPUがまだ使用されているリソースから読み取りまたは書き込みする読み取り/書き込みの危険が発生しないことを保証します。

表示セマフォに`frameIndex`を使用し、レンダリングセマフォに`imageIndex`を使用していることに注意してください。これは`vkQueuePresentKHR`（以下を参照）が特定の拡張機能（まだどこでも利用可能ではありません）なしでシグナルする方法を持っていないためです。これを回避するために、2つのセマフォタイプを切り離し、代わりにスワップチェーンイメージごとに1つの表示セマフォを使用します。これの詳細な説明は[Vulkanガイド](https://docs.vulkan.org/guide/latest/swapchain_semaphore_reuse.html)にあります。

!!! Warning

	送信は複数の待機とシグナルセマフォ、および待機ステージを持つことができます。私たちの（より複雑な）アプリケーションでは、グラフィックスを計算と混合する可能性があるため、同期スコープをできるだけ狭く保ち、GPUが作業を重ねられるようにすることが重要です。これはVulkanで正しくするのが最も困難な部分の1つです。エラーは[検証レイヤー](#validation-layers)で検出でき、パフォーマンスはベンダー固有のグラフィックスプロファイラでチェックできます。

作業が送信されたら、次のレンダリングループ反復のフレームインデックスを計算できます：

```cpp
frameIndex = (frameIndex + 1) % maxFramesInFlight;
```

### イメージの表示

レンダリング結果を画面に取得する最後のステップは、カラーアタッチメントとして使用した現在のスワップチェーンイメージを表示することです：

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

[vkQueuePresentKHR](https://docs.vulkan.org/refpages/latest/refpages/source/vkQueuePresentKHR.html)を呼び出すと、レンダリングセマフォを待機した後、イメージが表示のためにエンキューされます。これにより、レンダリングコマンドが完了するまでイメージが表示されないことが保証されます。

### イベントのポーリング

最後に、オペレーティングシステムのイベントキューを処理します。SDLのおかげで、このコードはプラットフォームに依存しません。イベントの処理は、SDLの[イベントポーリング関数](https://wiki.libsdl.org/SDL3/SDL_PollEvent)を呼び出してすべてのイベントが処理されるまでの追加のループ（レンダリングループ内）で行われます。関心のあるイベントタイプのみを処理します：

```cpp
float elapsedTime{ (SDL_GetTicks() - lastTime) / 1000.0f };
lastTime = SDL_GetTicks();
for (SDL_Event event; SDL_PollEvent(&event);) {

	// アプリケーションが閉じようとしている場合にループを終了
	if (event.type == SDL_EVENT_QUIT) {
		quit = true;
		break;
	}

	// マウスドラッグで選択されたオブジェクトを回転
	if (event.type == SDL_EVENT_MOUSE_MOTION) {
		if (event.button.button == SDL_BUTTON_LEFT) {
			objectRotations[shaderData.selected].x -= (float)event.motion.yrel * elapsedTime;
			objectRotations[shaderData.selected].y += (float)event.motion.xrel * elapsedTime;
		}
	}

	// マウスホイールでズーム
	if (event.type == SDL_EVENT_MOUSE_WHEEL) {
		camPos.z += (float)event.wheel.y * elapsedTime * 10.0f;
	}

	// アクティブなモデルインスタンスを選択
	if (event.type == SDL_EVENT_KEY_DOWN) {
		if (event.key.key == SDLK_PLUS || event.key.key == SDLK_KP_PLUS) {
			shaderData.selected = (shaderData.selected < 2) ? shaderData.selected + 1 : 0;
		}
		if (event.key.key == SDLK_MINUS || event.key.key == SDLK_KP_MINUS) {
			shaderData.selected = (shaderData.selected > 0) ? shaderData.selected - 1 : 2;
		}
	}

	// ウィンドウのサイズ変更
	if (event.type == SDL_EVENT_WINDOW_RESIZED) {
		updateSwapchain = true;
	}
}
```

アプリケーションにいくつかの対話性を持たせたいと考えます。そのために、`SDL_EVENT_MOUSE_MOTION`イベントで左ボタンが押されている間のマウスの動きに基づいて、現在選択されているモデルインスタンスの回転を計算します。`SDL_EVENT_MOUSE_WHEEL`のマウスホイールについても同様で、カメラのズームイン/アウトを可能にします。`SDL_EVENT_KEY_DOWN`イベントを使用して、プラスとマイナスキーでモデルインスタンス間を切り替えることができます。

`SDL_EVENT_QUIT`イベントは、アプリケーションが閉じようとしているときに呼び出されます。どのような方法でも。その場合、`quit`をtrueに設定し、外側のレンダリングループを終了して[クリーンアップ](#cleaning-up)部分にジャンプします。

オプションですが、ゲームではしばしば実装されませんが、`SDL_EVENT_WINDOW_RESIZED`イベントを介してサイズ変更も処理します。これにはスワップチェーンと関連リソースの再作成が必要です。

### スワップチェーンの再作成

ウィンドウのサイズが変更されたか、そのサーフェスが[古くなった](#acquire-next-image)場合、スワップチェーンを再作成する必要があります。これらの操作のいずれかがスワップチェーンの更新を要求する場合、それを再作成します：

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

最初は威圧的に見えますが、これは以前にスワップチェーンと深度イメージを作成するために使用したコードのほとんどです。これらを再作成する前に、[vkDeviceWaitIdle](https://docs.vulkan.org/refpages/latest/refpages/source/vkDeviceWaitIdle.html)を呼び出して、GPUが未完了のすべての操作を完了するのを待機する必要があります。これにより、これらのオブジェクトのいずれかがまだGPUによって使用されていないことが保証されます。

重要な違いの1つは、スワップチェーン作成情報の`oldSwapchain`メンバーを設定することです。これは再作成中に、アプリケーションがすでに取得したイメージの表示を継続できるようにするために必要です。これらを制御できないことを覚えておいてください。スワップチェーン（およびオペレーティングシステム）によって所有されるためです。それ以外は、既存のオブジェクト（`vkDestroy*`）を破棄し、以前と同じように新しいものを作成する単純な問題です。ただし、ウィンドウの新しいサイズを使用します。

## クリーンアップ

Vulkanリソースの破棄は作成と同じくらい明示的です。理論的には、何もせずにアプリケーションを終了し、代わりにオペレーティングシステムにクリーンアップさせることができます。しかし、適切にクリーンアップすることは常識であり、そうします。GPUで破棄したいリソースのいずれもまだ使用されていないことを確認するために、再びvkDeviceWaitIdleを呼び出します。その呼び出しが正常に完了すると、アプリケーションで作成したすべてのVulkan GPUオブジェクトのクリーンアップを開始できます：

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

コマンドの順序はVMAアロケータ、デバイス、およびインスタンスに対してのみ重要です。これらは、それらから作成されたすべてのオブジェクトの後にのみ破棄する必要があります。インスタンスは最後に削除する必要があります。そうすることで、検証レイヤー（有効な場合）から、適切に削除しなかったすべてのオブジェクトについて通知されます。明示的に破棄する必要があるリソースの1つはコマンドバッファーではありません。[vkDestroyCommandPool](https://docs.vulkan.org/refpages/latest/refpages/source/vkDestroyCommandPool.html)を呼び出すと、そのプールから割り当てられたすべてのコマンドバッファーが暗黙的に解放されます。

## 結びの言葉

これで、ラスタライズを実行し、最新のAPIバージョンと機能を活用するVulkanアプリケーションを作成する方法の基本的な理解ができたはずです。Vulkanは依然として比較的冗長なAPIであり、これはその明示的で低レベルな設計に固有です。しかし、Vulkanで何かを動作させるにはまだ多くのコードが必要ですが、理解しやすく、より柔軟であり、より複雑なアプリケーションの確実な基盤となります。

より広い視点から見ると、2026年のVulkanは以前よりも広範囲のユースケースをサポートしています。ラスタライズと計算に加えて、ハードウェアアクセラレートレイトレーシング、ビデオエンコーディングとデコーディング、機械学習、安全重要領域の機能も提供しています。

さらにリソースを探している場合は、[Vulkanドキュメントサイト](https://docs.vulkan.org/)をチェックしてください。これは仕様、チュートリアル、サンプルなど、複数のVulkanドキュメントリソースを便利な単一サイトに統合しています。
