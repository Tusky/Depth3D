 ////----------------//
 ///**Virtual Nose**///
 //----------------////


 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* VR Virtual Nose for reducing nausia AKA VR Sickness                                                                                                                            *//
 //* For Reshade 3.0+                                                                                                                                                               *//
 //*  ---------------------------------                                                                                                                                             *//
 //* This work is licensed under a Creative Commons Attribution 3.0 Unported License.                                                                                               *//
 //* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.                                                                              *//
 //* I would also love to hear about a project you are using it with.                                                                                                               *//
 //* https://creativecommons.org/licenses/by/3.0/us/																																*//
 //*																																												*//
 //* Jose Negrete AKA BlueSkyDefender																											                                   *//
 //*																																												*//
 //* http://reshade.me/forum/shader-presentation/2128-sidebyside-3d-depth-map-based-stereoscopic-shader                                                                             *//	
 //* ---------------------------------															                                                                                  *//
 //*																																												*//
 //*                                                    																															*//
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

uniform int BlurAdjust <
	ui_type = "drag";
	ui_min = 1; ui_max =  10;
	ui_label = "Blur Adjust";
	ui_tooltip = "Use this to adjust Nose Blur.\n"
				 "Default is Five.";
	ui_category = "Virtual Nose";
> = 5;

uniform int Ambiance <
	ui_type = "combo";
	ui_items = "Off\0On Shade\0On Color\0";
	ui_label = "Nose Ambiance";
	ui_tooltip = "Use this to allow ambiance to affect the nose.\n"
				 "Default is Off.";
	ui_category = "Virtual Nose";
> = 0;

uniform int Human_Skin_Color <
	#if Compatibility
	ui_type = "drag";
	#else
	ui_type = "slider";
	#endif
	ui_min = -4; ui_max = 4;
	ui_label = "Pick Base Skin Color";
	ui_tooltip = "This option allows you to pick your skin color and turns on the Virtual Nose.\n"
				 "Default is Zero, Off.";
	ui_category = "Virtual Nose";
> = 0;

uniform float3 NoseWH <
	#if Compatibility
	ui_type = "drag";
	#else
	ui_type = "slider";
	#endif
	ui_min = -5.0; ui_max = 5.0;
	ui_label = "Adjust Nose";
	ui_tooltip = "Adjust the Width and Height of the Virtual Nose
				 "Default is float3(0,2.5,0).";
	ui_category = "Virtual Nose";
> = float3(0,2.5,0);

//Human Skin Color//
float3 HSC()
{
	float3 HSC;
	if(Human_Skin_Color == -4)
		HSC = float3(247,217,214);
	else if(Human_Skin_Color == -3)
		HSC = float3(240,186,173);
	else if(Human_Skin_Color == -2)
		HSC = float3(212,128,107);
	else if(Human_Skin_Color == -1)
		HSC = float3(230,178,148);
	else if(Human_Skin_Color == 0)
		HSC = float3(255,255,255);
	else if(Human_Skin_Color == 1)
		HSC = float3(235,179,133);
	else if(Human_Skin_Color == 2)
		HSC = float3(195,116,77);
	else if(Human_Skin_Color == 3)
		HSC = float3(69,42,29);
	else if(Human_Skin_Color == 4)
		HSC = float3(34,21,15);
	return HSC;
}
/////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define TextureSize float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#define HumanColor float3( HSC().x/255, HSC().y/255, HSC().z/255)//RGB Conversion 0-1 range
	
texture BackBufferTex : COLOR;

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};
	
texture texShade { Width = 256*0.5; Height =  256*0.5; Format = RGBA8; MipLevels = 8;}; //Sample at 256x256*0.5 and a mip bias of 8 should be 1x1 

sampler ShadeSampler
	{
		Texture = texShade;
		MipLODBias = 8.0f; //Luminance adapted luminance value from 1x1 Texture Mip lvl of 8
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
	
texture texNM { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 3;};

sampler NMSampler
	{
		Texture = texNM;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
		
float4 AbianceBlur(float2 texcoord : TEXCOORD0)
{
	float2 XYoffset[4] = { float2( 0, 1 ), float2( 0,-1 ), float2( 1, 0 ), float2(-1, 0) };
	float4 Blur; 
		   Blur += tex2D(ShadeSampler,texcoord + XYoffset[0] * 5 * pix);
		   Blur += tex2D(ShadeSampler,texcoord + XYoffset[1] * 5 * pix);
		   Blur += tex2D(ShadeSampler,texcoord + XYoffset[2] * 5 * pix);
		   Blur += tex2D(ShadeSampler,texcoord + XYoffset[3] * 5 * pix);
		   Blur /= 4;
	return Blur;
}			
float4 NoseCreation(float2 texcoord : TEXCOORD0)
{
	texcoord.x -= 0.5*TextureSize.x*pix.x;
	texcoord.y -= 0.5*TextureSize.y*pix.y;	
	//Nose Height
	texcoord.y += (-2.5+NoseWH.y) * 25.0f * pix.y;
	//Nose Size
	texcoord *= 1 + (5-NoseWH.z) * 0.05f;
	//Nose Width
	texcoord.x *= 1 + (-NoseWH.x) * 0.10f;
	//Strange Bug if I remove the -0 it loses postion????	 
	float2 XY_A = float2(0 - texcoord.x * 5.0f, 0.75f - texcoord.y);//Bridge
	float dist_A = distance(XY_A.x,texcoord.x)+distance(XY_A.y,texcoord.y);
	
	float2 XY_B = float2(texcoord.x * 5.395f, 2.0f - texcoord.y * 4.165f);//Nostro
	float dist_B = XY_B.x * XY_B.x + XY_B.y * XY_B.y;

	texcoord.x *= 0.9625;
	float2 XY_C = float2(0 - texcoord.x * 5.0f, 0.75f -texcoord.y);//Bridge
	float dist_C = distance(XY_C.x,texcoord.x)+distance(XY_C.y,texcoord.y);
	//float2 MXY_B = texcoord * JJ;
	float2 XY_D = float2(texcoord.x * 5.395f, 2.0f - texcoord.y * 4.165f);//Nostro
	float dist_D = XY_D.x * XY_D.x + XY_D.y * XY_D.y;
	
	return float4(dist_A,dist_B,dist_C,dist_D);
}

float4 NoseColor(float2 texcoord : TEXCOORD0)
{
	texcoord.x -= 0.5*TextureSize.x*pix.x;
	texcoord.y -= 0.5*TextureSize.y*pix.y;
	float4 Nose = smoothstep(0,1,(-texcoord.y * (-texcoord.x * 500.0f) * texcoord.y) * texcoord.x  + 0.5f);
		   Nose *= float4(HumanColor, 1); // Nose Color
	float DB  = 8;//Dither Bit
	float noise = frac(sin(dot(texcoord, float2(12.9898, 78.233))) * 43758.5453);
	float dither_shift = (1.0 / (pow(2,DB) - 1.0));
	float dither_shift_half = (dither_shift * 0.5);
		  dither_shift = dither_shift * noise - dither_shift_half;
		  Nose.rgb += -dither_shift;
		  Nose.rgb += dither_shift;
		  Nose.rgb += -dither_shift;
	return Nose;
}

float4 NoseMask(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 Out;		
	float NC_A = NoseCreation(texcoord).x, NC_B = NoseCreation(texcoord).y, NC_C = NoseCreation(texcoord).z, NC_D = NoseCreation(texcoord).w, M;
		
		if(NC_A < 1 || NC_B < 1)
			{	
				if(Ambiance == 0)
					Out.rgb = NoseColor(texcoord).rgb;
				else if(Ambiance == 1)
					Out.rgb = NoseColor(texcoord).rgb * dot(AbianceBlur(texcoord).rgb, float3(0.299, 0.587, 0.114));
				else if(Ambiance == 2)
					Out.rgb = NoseColor(texcoord).rgb * AbianceBlur(texcoord).rgb;
			}
		else
			{
				Out.rgb = tex2D(BackBuffer,texcoord).rgb;	
			}
			
		if(NC_C < 1 || NC_D < 1)
			M = 1;
		else
			M = 0;
		
	return float4(Out.rgb,M);
}

float4 VNose(float2 texcoord : TEXCOORD0)
{
	int Blur_Boost = floor(BlurAdjust * 0.5);
	float BA = BlurAdjust * 2.0f;
	float4 Blur, Out;
	if(Human_Skin_Color < 0 || Human_Skin_Color > 0)
	{	  
		   Blur += tex2Dlod(NMSampler,float4( texcoord + float2( 1, 0) * BA * pix,0,Blur_Boost));
		   Blur += tex2Dlod(NMSampler,float4( texcoord + float2(-1, 0) * BA * pix,0,Blur_Boost));
		   Blur += tex2Dlod(NMSampler,float4( texcoord + float2( 1, 0) * (BA * 0.75) * pix,0,Blur_Boost));
		   Blur += tex2Dlod(NMSampler,float4( texcoord + float2(-1, 0) * (BA * 0.75) * pix,0,Blur_Boost));
		   Blur += tex2Dlod(NMSampler,float4( texcoord + float2( 1, 0) * (BA * 0.50) * pix,0,Blur_Boost));
		   Blur += tex2Dlod(NMSampler,float4( texcoord + float2(-1, 0) * (BA * 0.50) * pix,0,Blur_Boost));
		   Blur += tex2Dlod(NMSampler,float4( texcoord + float2( 1, 0) * (BA * 0.25) * pix,0,Blur_Boost));
		   Blur += tex2Dlod(NMSampler,float4( texcoord + float2(-1, 0) * (BA * 0.25) * pix,0,Blur_Boost));
		   Blur /= 8;
		float NM = tex2D(NMSampler,texcoord).w;  
		Out = NM ? Blur : tex2D(BackBuffer,texcoord);
	}
	else
	{
		Out = tex2D(BackBuffer,texcoord);
	}	
	
	return Out;
}

float4 VRLeft(float2 texcoord : TEXCOORD0)
{
	return tex2D(BackBuffer,float2(texcoord.x*0.5,texcoord.y));
}

float4 Shade(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{	
	float2 XYoffset[4] = { float2( 0, 1 ), float2( 0,-1 ), float2( 1, 0 ), float2(-1, 0) };
	float4 Blur; 
		   Blur += VRLeft(texcoord + XYoffset[0] * 10 * pix);
		   Blur += VRLeft(texcoord + XYoffset[1] * 10 * pix);
		   Blur += VRLeft(texcoord + XYoffset[2] * 10 * pix);
		   Blur += VRLeft(texcoord + XYoffset[3] * 10 * pix);
		   Blur /= 4;
	return Blur; 
}
////////////////////////////////////////////////////////Logo/////////////////////////////////////////////////////////////////////////
uniform float timer < source = "timer"; >;

float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float PosX = 0.5*BUFFER_WIDTH*pix.x,PosY = 0.5*BUFFER_HEIGHT*pix.y;	
	float4 Color = VNose(texcoord),Done,Website,D,E,P,T,H,Three,DD,Dot,I,N,F,O;
	
	if(timer <= 10000)
	{
	//DEPTH
	//D
	float PosXD = -0.035+PosX, offsetD = 0.001;
	float4 OneD = all( abs(float2( texcoord.x -PosXD, texcoord.y-PosY)) < float2(0.0025,0.009));
	float4 TwoD = all( abs(float2( texcoord.x -PosXD-offsetD, texcoord.y-PosY)) < float2(0.0025,0.007));
	D = OneD-TwoD;
	
	//E
	float PosXE = -0.028+PosX, offsetE = 0.0005;
	float4 OneE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.009));
	float4 TwoE = all( abs(float2( texcoord.x -PosXE-offsetE, texcoord.y-PosY)) < float2(0.0025,0.007));
	float4 ThreeE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.001));
	E = (OneE-TwoE)+ThreeE;
	
	//P
	float PosXP = -0.0215+PosX, PosYP = -0.0025+PosY, offsetP = 0.001, offsetP1 = 0.002;
	float4 OneP = all( abs(float2( texcoord.x -PosXP, texcoord.y-PosYP)) < float2(0.0025,0.009*0.682));
	float4 TwoP = all( abs(float2( texcoord.x -PosXP-offsetP, texcoord.y-PosYP)) < float2(0.0025,0.007*0.682));
	float4 ThreeP = all( abs(float2( texcoord.x -PosXP+offsetP1, texcoord.y-PosY)) < float2(0.0005,0.009));
	P = (OneP-TwoP) + ThreeP;

	//T
	float PosXT = -0.014+PosX, PosYT = -0.008+PosY;
	float4 OneT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosYT)) < float2(0.003,0.001));
	float4 TwoT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosY)) < float2(0.000625,0.009));
	T = OneT+TwoT;
	
	//H
	float PosXH = -0.0071+PosX;
	float4 OneH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.001));
	float4 TwoH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.009));
	float4 ThreeH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.003,0.009));
	H = (OneH-TwoH)+ThreeH;
	
	//Three
	float offsetFive = 0.001, PosX3 = -0.001+PosX;
	float4 OneThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.009));
	float4 TwoThree = all( abs(float2( texcoord.x -PosX3 - offsetFive, texcoord.y-PosY)) < float2(0.003,0.007));
	float4 ThreeThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.001));
	Three = (OneThree-TwoThree)+ThreeThree;
	
	//DD
	float PosXDD = 0.006+PosX, offsetDD = 0.001;	
	float4 OneDD = all( abs(float2( texcoord.x -PosXDD, texcoord.y-PosY)) < float2(0.0025,0.009));
	float4 TwoDD = all( abs(float2( texcoord.x -PosXDD-offsetDD, texcoord.y-PosY)) < float2(0.0025,0.007));
	DD = OneDD-TwoDD;
	
	//Dot
	float PosXDot = 0.011+PosX, PosYDot = 0.008+PosY;		
	float4 OneDot = all( abs(float2( texcoord.x -PosXDot, texcoord.y-PosYDot)) < float2(0.00075,0.0015));
	Dot = OneDot;
	
	//INFO
	//I
	float PosXI = 0.0155+PosX, PosYI = 0.004+PosY, PosYII = 0.008+PosY;
	float4 OneI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosY)) < float2(0.003,0.001));
	float4 TwoI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYI)) < float2(0.000625,0.005));
	float4 ThreeI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYII)) < float2(0.003,0.001));
	I = OneI+TwoI+ThreeI;
	
	//N
	float PosXN = 0.0225+PosX, PosYN = 0.005+PosY,offsetN = -0.001;
	float4 OneN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN)) < float2(0.002,0.004));
	float4 TwoN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN - offsetN)) < float2(0.003,0.005));
	N = OneN-TwoN;
	
	//F
	float PosXF = 0.029+PosX, PosYF = 0.004+PosY, offsetF = 0.0005, offsetF1 = 0.001;
	float4 OneF = all( abs(float2( texcoord.x -PosXF-offsetF, texcoord.y-PosYF-offsetF1)) < float2(0.002,0.004));
	float4 TwoF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0025,0.005));
	float4 ThreeF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0015,0.00075));
	F = (OneF-TwoF)+ThreeF;
	
	//O
	float PosXO = 0.035+PosX, PosYO = 0.004+PosY;
	float4 OneO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.003,0.005));
	float4 TwoO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.002,0.003));
	O = OneO-TwoO;
	}
	
	Website = D+E+P+T+H+Three+DD+Dot+I+N+F+O ? float4(1.0,1.0,1.0,1) : Color;
	
	if(timer >= 10000)
	{
	Done = Color;
	}
	else
	{
	Done = Website;
	}

	return Done;
}

///////////////////////////////////////////////////////////ReShade.fxh/////////////////////////////////////////////////////////////

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

//*Rendering passes*//
technique Virtual_Nose
{		
			pass Ambiance_Shading
		{
			VertexShader = PostProcessVS;
			PixelShader = Shade;
			RenderTarget = texShade;
		}
			pass Nose_Mask
		{
			VertexShader = PostProcessVS;
			PixelShader = NoseMask;
			RenderTarget = texNM;
		}
			pass PBD
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}