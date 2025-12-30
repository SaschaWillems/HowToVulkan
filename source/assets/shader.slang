/* Copyright (c) 2025, Sascha Willems
 *
 * SPDX-License-Identifier: MIT
 *
 */

struct VSInput {
	float3 Pos;
	float2 UV;
};

Sampler2D textures[];

struct UBO {
    float4x4 projection;
    float4x4 view;
    float4x4 model[3];
    uint32_t selected;
};

struct VSOutput {
	float4 Pos : SV_POSITION;
    float2 UV;
    float3 Factor;
    uint32_t InstanceIndex;
};

[shader("vertex")]
VSOutput main(VSInput input, uniform UBO *ubo, uint instanceIndex : SV_VulkanInstanceID) {
	VSOutput output;
	output.UV = input.UV;
    output.Pos = mul(ubo->projection, mul(ubo->view, mul(ubo->model[instanceIndex], float4(input.Pos.xyz, 1.0))));
    output.Factor = (ubo.selected == instanceIndex ? 3.0f : 1.0f);
    output.InstanceIndex = instanceIndex;
    return output;
}

[shader("fragment")]
float4 main(VSOutput input) {
    return float4(textures[input.InstanceIndex].Sample(input.UV).rgb * input.Factor, 1.0);
}