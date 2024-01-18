## 0. 背景

Youtube上视频[Painting a Landscape with Maths](https://www.youtube.com/watch?v=BFld4EBO2RE&list=PL0EpikNmjs2CYUMePMGh3IjjP4tQlYqji)，很有趣。于是，实现之。

它的online代码在[这里](https://www.shadertoy.com/view/4ttSWf)。目录中的scene.cpp来自这个地址。

## 1. 地表

- 地表是连续起伏的平面，并且有很多凸起、凹陷的山丘、山谷、表面碎石效果等 - 2元多项式函数模拟地表平面，使用泰勒级数(或者傅立叶级数)展开方式叠加不同次幂的多项式，叠加过程中进行一些旋转。在一个无穷大的连续平面上产生多项式表面并不现实，将平面以$x、z$轴分为单位格子，为每个格子生成多项式平面；为了格子与格子的平面连续，使用格子的4个顶点$a、b、c、d$作为控制点，每个格子的多项式如下：

	$$f_{i,j}(x,z)=a_{ij}+(b_{ij}-a_{ij})S(x-i)+(c_{ij}-a_{ij})S(z-j)+(a_{ij}-b_{ij}-c_{ij}+d_{ij})S(x-i)S(z-j)$$

	其中：

	$S$为平滑函数，输入$0～1$,输出也是$0～1$，并且在这两点一阶导数为$0$。

	$$S(\lambda)=3\lambda^2-2\lambda^3$$

	$S$函数是$Smoothstep$函数的简称，可以泛化为三个参数，$上限b、下限a、变量x$。

	$$S(a,b,x)=3\lambda^2-2\lambda^3$$
	$$\lambda=min(1,max(0, \frac{x-a}{b-a}))$$

	一个格子的$a$点，是周围三个格子的$b、c、d$点。

	$$a_{i,j}=b_{i-1,j}=c_{i,j-1}=d_{i-1,j-1}$$

	产生$a$的方法可以很多，如果我们希望可以重现，则不要用随机数，这里提供一个视频中使用的产生$a$的算法：$a_{i,j}=2\{uv(u+v)\}-1$，其中 $(u,v)=50\{\frac{(i,j)}{\pi}\}$，$\{\}$表示取小数部分。

	叠加大量的不同“频率”的多项式函数表面则得到了我们的地表函数：
	$$F(p_{xz})=N(p_{xz}) + \frac{1}{2}N(2Mp_{xz}) + \frac{1}{2^2}N(2^2M^2p_{xz})+\dots+\frac{1}{2^n}N(2^nM^np_{xz})$$

	旋转矩阵 $M=\begin{pmatrix} 4/5	&-3/5 \\ 3/5	&4/5 \end{pmatrix}$，$N$代表函数$f$，是$Noise$的简称。

	之所以使用$3、4、5$这样的勾股数构造旋转函数，是因为这样可以避免大量的$\cos$、$\sin$计算。

	$$f(P_{xz})=600 \times F(\frac{P_{xz}}{2000})+600$$

## 2. 地表颜色

- 根据地标平面表面的法向量与点光源点乘的结果，考虑遮挡以及阴影的平滑效果产生地表的光线；法向量可以由平面的两个切线方向的向量点乘得到。$f(x,z)$为地表函数、s为光线向量、$\theta$、$\varphi$为三维极坐标的角度分量（视频中选择的 $\theta=1.3$、$\varphi=3.93$）、$p$为点坐标、$color_{sky}$为天空颜色、$color_{earth}$为地面颜色、$color_{grass}$为地面上的植被，$material$公式反应了地面与杂草的比例，$color_p$为点$p$处的颜色、$sh$为阴影系数。

	$$n=\begin{pmatrix} 1 \\ \frac{\partial f}{\partial z} \\ 0 \end{pmatrix} \times \begin{pmatrix} 0 \\ \frac{\partial f}{\partial x} \\ 1 \end{pmatrix}$$

	$$ s=\begin{pmatrix} \sin\theta \cdot \sin\varphi \\ \cos\theta \\ \sin\theta \cdot \cos\varphi \end{pmatrix} $$

	$$ color=material \cdot lighting $$

	$$ material = color_{earth} \cdot (1-\lambda) + color_{grass} \cdot \lambda $$

	$$ \lambda = S(0.6, 0.7, n_y) $$

	$$ color_p = color_{earth} \cdot ( (n \cdot s)_{+} sh(p) + \frac{1+n_y}{2} \cdot {\frac{color_{sky}}{10}} + (n \cdot {-s})_+ \cdot {\frac{color_{earth}}{10}} ) $$

	这里，$color_p$公式的括号中三个分量是直射光线，天空漫反射，环境漫反射。函数$R$让阴影变得平滑。

	$$ sh(p)=S(0,1,R_{min})$$

	$$ R(t)=32 \cdot \frac{d(f,p+t \cdot s)}{t} $$

## 大气着色

- 太阳光源是白色，但不同频率的光线在大气中的散射，衰减不同，可以使用rgb三个通道的值进行指数衰减，产生蓝天效果，如果衰减速度快则产生迷雾效果。调整适当的衰减系数，得到远处的地表会略微模糊的效果，产生接近真实感觉的近处清晰、远处略微模糊效果。

	$$color_p = \lambda \cdot color_p + (1-\lambda) \cdot color_{gray}$$

	$$\lambda(t)=e^{-0.00050 \cdot t \cdot (1,2,4)^T}$$

## 悬崖峭壁

- 制造一些悬崖峭壁
	$$c(\lambda)=S(500,600,\lambda)$$

	让500米高的表面直接升高90米
	$$ f(x,z) \rightarrow f(x,z)+90c(f(x,z)) $$

## 云彩和天空着色

- 天空着色+云彩
	$$color=(color_{sky}-0.4 \cdot v_{y})\cdot(1-\lambda)+\lambda$$

	天空位置在$y=2500$位置

	$$p_y=2500$$
	$$\lambda=S (-2.0,0.6, F(0.002 p_{xz}))\cdot 0.4$$

## 地面增加一些植被

- 增加植被实际上就是增加一些绿色区域，地面的 $material = color_{earth} \cdot (1-\lambda) + color_{grass} \cdot \lambda$，其中 $\lambda = S(0.6, 0.7, n_y)$
- 增加一些树

	1. 地表使用的是多个频率的多项式叠加：$F(p_{xz})=\sum_{n\in\mathcal{N}} \frac{1}{2^n}N(M^n2^np_{xz})$，其中$\mathcal{N}=\{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19\}$。
	因为要"种树"，地面的细节就不需要这么多，可以移除$\mathcal{N}=\{7,8,9,10,11,12,13\}$
	2.
