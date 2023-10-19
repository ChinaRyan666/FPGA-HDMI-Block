# （八）零基础FPGA图像处理——HDMI方块移动实验
# 0 致读者


此篇为专栏 **《Ryan的FPGA学习笔记》** 的第八篇，记录我的学习 FPGA 的一些开发过程和心得感悟，刚接触 FPGA 的朋友们可以先去此专栏置顶[《FPGA零基础入门学习路线》](http://t.csdnimg.cn/DPmCJ)来做最基础的扫盲。

本篇内容基于笔者实际开发过程和正点原子资料撰写，将会详细讲解此FPGA实验的全流程，**诚挚**地欢迎各位读者在评论区或者私信我交流！

本文的工程文件**开源地址**如下（基于**ZYNQ7020**，大家 **clone** 到本地就可以直接跑仿真，如果要上板请根据自己的开发板更改约束即可）：

> [https://github.com/ChinaRyan666/FPGA-HDMI-Block](https://github.com/ChinaRyan666/FPGA-HDMI-Block)

<br/>
<br/>


# 1 实验任务

本文的实验任务是使用 **ZYNQ** 开发板上的 HDMI 接口在显示器上显示一个不停移动的方块，要求方块移动到边界处时能够改变移动方向。显示分辨率为 **1280*720**， 刷新速率为 **60hz**。



<br/>
<br/>


# 2 HDMI 简介

我在本专栏的[《（七）零基础FPGA图像处理——HDMI彩条显示实验》](http://t.csdnimg.cn/TcfNH)中对 **HDMI** 视频传输标准作了详细的介绍， 包括 **HDMI** 接口定义、行场同步时序、以及显示分辨率等。如果大家对这部分内容不是很熟悉的话， 请参考[《（七）零基础FPGA图像处理——HDMI彩条显示实验》](http://t.csdnimg.cn/TcfNH)中的 **HDMI** 简介部分。





<br/>
<br/>



# 3 程序设计
## 3.1 总体模块设计

本次实验总体模块框图与[ HDMI 彩条显示实验](http://t.csdnimg.cn/TcfNH) 完全一致， 只是需要对 **lcd_display** 模块进行修改。

由此得出本次实验的**系统框图**如下所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/3e77117a424444b5a5e939118ad62c90.png#pic_center)

<br/>

## 3.2 HDMI 显示模块设计


根据实验任务可知，本文只需要修改 **video_display** 模块内部的代码。在本次实验中，为了完成方块的显示，需要同时使用**像素点的横坐标**和**纵坐标**来绘制**方块所在的矩形区域**，另外还需要知道矩形区域左上角的顶点坐标。 由于 **RGB** 显示的图像在**行场同步信号**的同步下不停的刷新， 因此只要**连续改变方块左上角顶点的坐标**， 并在新的坐标点处重新绘制方块，即可实现方块移动的效果。

**HDMI 显示模块框图**与彩条显示模块完全一致，模块框图如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/9f2b89626fd94fccb48c62723f2cbba1.png)

<br/>

### 3.2.1 绘制波形图

本次方块的大小为 **40x40**，且该方块的显示范围为 **x 坐标**为（**40~ 1239**）， **y 坐标**为(**40~ 679**)。其中 **block_x** 为方块当前横坐标， **block_y** 为当前方块纵坐标。当方块的宽度确定时， 如果我们知道方块左上方顶点的坐标，就能轻而易举的画出整个方块区域。因此，我们将方块的移动简化为其左上角顶点的移动。

>由于像素时钟相对于方块移动速度而言过快， 我们通过计数器对时钟计数， 得到一个频率为 **100hz** 的脉冲信号 **move_en**，用它作为使能信号来控制方块的移动。 方块的移动方向分为水平方向 **h_direct** 和竖直方向 **v_direct**，当方块移动到上下边框时， 竖直移动方向改变； 当方块移动到左右边框时，水平移动方向改变。当 **move_en** 的频率为 **100hz** 时，方块每秒钟在水平和竖直方向上分别移动 **100** 个像素点的距离， 也可以通过调整 **move_en** 的频率，来加快或减慢方块移动的速度。

根据显示模块分析，我们可以进行**波形图的绘制**：


![在这里插入图片描述](https://img-blog.csdnimg.cn/01611ed5c1264e048333f61ad7a98e53.png)

<br/>

### 3.2.2 代码编写

根据显示模块分析以及绘制的波形图，编写的**显示模块**代码如下：

```
module  video_display(
    input             pixel_clk,                //VGA驱动时钟
    input             sys_rst_n,                //复位信号
    
    input      [10:0] pixel_xpos,               //像素点横坐标
    input      [10:0] pixel_ypos,               //像素点纵坐标    
    output reg [23:0] pixel_data                //像素点数据
    );    

//parameter define    
parameter  H_DISP  = 11'd1280;                  //分辨率--行
parameter  V_DISP  = 11'd720;                   //分辨率--列
parameter  DIV_CNT = 22'd750000;				//分频计数器

localparam SIDE_W  = 11'd40;                    //屏幕边框宽度
localparam BLOCK_W = 11'd40;                    //方块宽度
localparam BLUE    = 24'h0000ff;    			//屏幕边框颜色 蓝色
localparam WHITE   = 24'hffffff;    			//背景颜色 白色
localparam BLACK   = 24'h000000;    			//方块颜色 黑色


//reg define
reg [10:0] block_x = SIDE_W ;                   //方块左上角横坐标
reg [10:0] block_y = SIDE_W ;                   //方块左上角纵坐标
reg [21:0] div_cnt;                             //时钟分频计数器
reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
reg        v_direct;                            //方块竖直移动方向，1：向下，0：向上

//wire define   
wire move_en;                                   //方块移动使能信号，频率为100hz

//*****************************************************
//**                    main code
//*****************************************************
assign move_en = (div_cnt == DIV_CNT) ? 1'b1 : 1'b0;

//通过对div驱动时钟计数，实现时钟分频
always @(posedge pixel_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)
        div_cnt <= 22'd0;
    else begin
        if(div_cnt < DIV_CNT) 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 22'd0;                   //计数达10ms后清零
    end
end

//当方块移动到边界时，改变移动方向
always @(posedge pixel_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin
        h_direct <= 1'b1;                       //方块初始水平向右移动
        v_direct <= 1'b1;                       //方块初始竖直向下移动
    end
    else begin
        if(block_x == SIDE_W + 1'b1)            //到达左边界时，水平向右
            h_direct <= 1'b1;               
        else                                    //到达右边界时，水平向左
        if(block_x == H_DISP - SIDE_W - BLOCK_W + 1'b1)
            h_direct <= 1'b0;               
        else
            h_direct <= h_direct;
            
        if(block_y == SIDE_W + 1'b1)            //到达上边界时，竖直向下
            v_direct <= 1'b1;                
        else                                    //到达下边界时，竖直向上
        if(block_y == V_DISP - SIDE_W - BLOCK_W + 1'b1)
            v_direct <= 1'b0;               
        else
            v_direct <= v_direct;
    end
end

//根据方块移动方向，改变其纵横坐标
always @(posedge pixel_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin
        block_x <= SIDE_W + 1'b1;                     //方块初始位置横坐标
        block_y <= SIDE_W + 1'b1;                     //方块初始位置纵坐标
    end
    else if(move_en) begin
        if(h_direct) 
            block_x <= block_x + 1'b1;          //方块向右移动
        else
            block_x <= block_x - 1'b1;          //方块向左移动
            
        if(v_direct) 
            block_y <= block_y + 1'b1;          //方块向下移动
        else
            block_y <= block_y - 1'b1;          //方块向上移动
    end
    else begin
        block_x <= block_x;
        block_y <= block_y;
    end
end

//给不同的区域绘制不同的颜色
always @(posedge pixel_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) 
        pixel_data <= BLACK;
    else begin
        if(  (pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
          || (pixel_ypos <= SIDE_W) || (pixel_ypos > V_DISP - SIDE_W))
            pixel_data <= BLUE;                 //绘制屏幕边框为蓝色
        else
        if(  (pixel_xpos >= block_x - 1'b1) && (pixel_xpos < block_x + BLOCK_W - 1'b1)
          && (pixel_ypos >= block_y) && (pixel_ypos < block_y + BLOCK_W))
            pixel_data <= BLACK;                //绘制方块为黑色
        else
            pixel_data <= WHITE;                //绘制背景为白色
    end
end

endmodule
```

代码中 **第 15 至 19 行**声明了一系列的参数，方便大家修改**边框尺寸**、**方块大小**、 以及**各部分的颜色**等。 其中**边框尺寸**和**方块宽度**均以**像素点**为单位。当方块的**宽度**确定时， 如果我们知道方块左上方顶点的坐标，就能轻而易举的画出整个方块区域。因此，我们将方块的移动简化为其**左上角顶点的移动**。

代码**第 98 至 112 行**根据 **RGB 驱动模块**输出的**纵横坐标**判断当前像素点所在的区域， 对不同区域中的像素点赋以不同的颜色值，从而实现**边框**、**方块**以及**背景颜色**的绘制。

<br/>

## 3.3 顶层模块编写

实验工程的其他各子功能模块均与本专栏上一篇博客[ HDMI 彩条显示实验](http://t.csdnimg.cn/TcfNH) 完全一致，在本文我们只需要按照 [ HDMI 彩条显示实验](http://t.csdnimg.cn/TcfNH) 对顶层模块进行例化即可。

顶层模块 **top_hdmi_block_move** 的代码如下：

```
module  top_hdmi_block_move(
    input          sys_clk,
	input          sys_rst_n,
	
    output         tmds_clk_n,
    output         tmds_clk_p,
    output  [2:0]  tmds_data_n,
    output  [2:0]  tmds_data_p
);

//*****************************************************
//**                    main code
//*****************************************************

//wire define
wire          pixel_clk;
wire          pixel_clk_5x;
wire  [10:0]  pixel_xpos_w;
wire  [10:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_w;
wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;

//例化MMCM/PLL IP核
clk_wiz_0  clk_wiz_0
(
    // Clock out ports
    .clk_out1     ( pixel_clk ),     // output pixel_clk_74_25m
    .clk_out2     ( pixel_clk_5x ),  // output pixel_clk_x5_371_25m
    
	// Status and control signals
    .reset   ( ~sys_rst_n ),                 // input reset
    .locked  (),                             // output locked
    
	// Clock in ports
    .clk_in1 ( sys_clk )                     // input clk_in1
);

//例化RGB数据驱动模块
video_driver  u_video_driver(
    .pixel_clk      ( pixel_clk ),
    .sys_rst_n      ( sys_rst_n ),

    .video_hs       ( video_hs ),
    .video_vs       ( video_vs ),
    .video_de       ( video_de ),
    .video_rgb      ( video_rgb ),
	.data_req		(),

    .pixel_xpos     ( pixel_xpos_w ),
    .pixel_ypos     ( pixel_ypos_w ),
	.pixel_data     ( pixel_data_w )
);

//例化RGB数据显示模块
video_display  u_video_display(
    .pixel_clk      ( pixel_clk ),
    .sys_rst_n      ( sys_rst_n ),

    .pixel_xpos     ( pixel_xpos_w ),
    .pixel_ypos     ( pixel_ypos_w ),
    .pixel_data     ( pixel_data_w )
);

//例化HDMI驱动模块
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (sys_rst_n ),
                
    .video_din      (video_rgb),
    .video_hsync    (video_hs), 
    .video_vsync    (video_vs),
    .video_de       (video_de),
                
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n), 
    .tmds_oen       ()                    //预留的端口，本次实验未用到
    );

endmodule
```






<br/>
<br/>


# 4 仿真验证

## 4.1 编写TestBench

顶层模块参考代码介绍完毕，开始对顶层模块进行**仿真**。代码编写如下：

```
module tb_top_hdmi_block_move();

reg          sys_clk	;
reg          sys_rst_n	;
						
wire         tmds_clk_n	;
wire         tmds_clk_p	;
wire  [2:0]  tmds_data_n;
wire  [2:0]  tmds_data_p;

initial begin
	sys_clk = 1'b1;
	sys_rst_n <= 1'b0;
	#201
	sys_rst_n <= 1'b1;
end

always #10 sys_clk <= ~sys_clk;

defparam top_hdmi_block_move_inst.u_video_display.DIV_CNT = 75;

top_hdmi_block_move top_hdmi_block_move_inst(
    .sys_clk	(sys_clk	),
	.sys_rst_n	(sys_rst_n	),

    .tmds_clk_n	(tmds_clk_n	),
    .tmds_clk_p	(tmds_clk_p	),
    .tmds_data_n(tmds_data_n),
    .tmds_data_p(tmds_data_p)
);

endmodule
```

>由于分频计数器数值太大，所以在仿真代码的**第 20 行**通过调用模块的映射，对 **DIV_CNT** 的参数进行修改，从而缩短整体模块仿真的时间。

<br/>

## 4.2 仿真波形分析


接下来打开 **Modelsim** 软件对代码进行仿真，仿真的波形我们重点来看一下 **HDMI 显示模块**部分的波形图，如下图所示：

![在这里插入图片描述](https://img-blog.csdnimg.cn/be86356fb38e4099b02548a07c25706b.png#pic_center)

<center>HDMI 显示模块仿真波形</center>
<br/>
<br/>

![在这里插入图片描述](https://img-blog.csdnimg.cn/5f9ba218c6654eaab638bae294628b88.png#pic_center)

<center>div_cnt 仿真波形图</center>
<br/>
<br/>

>**div_cnt** 的最大计数为 75，当计数器计数到 74 是 **move_en** 拉高一个时钟周期，当计数到最大值后计数器清零。


![在这里插入图片描述](https://img-blog.csdnimg.cn/8f65275259864423a4b5bc1f202a80d8.png)

<center>行场像素点 a</center>
<br/>
<br/>

![在这里插入图片描述](https://img-blog.csdnimg.cn/cd5c26d496f843bc8025025955e59ac8.png)

<center>行场像素点 b</center>
<br/>
<br/>

![在这里插入图片描述](https://img-blog.csdnimg.cn/6bafb57628c14690927184730f9ccb2f.png)
<center>行场信号像素点 c</center>
<br/>
<br/>

> 从行场信号像素点的仿真图，可以看出横坐标的像素点为 **1~ 1280**，纵坐标的像素点为 **1~ 720**，与我们编写的代码数据是一致的。


![在这里插入图片描述](https://img-blog.csdnimg.cn/739063b39a1f4a40b8863b24781f106d.png)

<center>方块垂直移动方向波形 a</center>
<br/>
<br/>![在这里插入图片描述](https://img-blog.csdnimg.cn/c65fb7117cdf4c2886ddf2a2bb4937c3.png)

<center>方块垂直移动方向波形 b</center>
<br/>
<br/>


>当 **block_y** 等于 **41** 时， **v_direct** 的使能拉高，当计数到 **640** 时， **v_direct** 的使能拉低。


![在这里插入图片描述](https://img-blog.csdnimg.cn/e43afaf88d7a4d8ab529844f9bd48267.png)

<center>方块水平移动方向波形 a</center>
<br/>
<br/>

![在这里插入图片描述](https://img-blog.csdnimg.cn/3984b5d11b8c4774baee9e0db3a2b7d5.png)

<center>方块水平移动方向波形 b</center>
<br/>
<br/>


> 方块水平移动的使能信号 **h_direct** 同理，当 **block_x** 等于 **41** 时，**h_direct** 使能拉高；当 **block** 等于 **1200** 时，**hdirect** 的使能拉低。


![在这里插入图片描述](https://img-blog.csdnimg.cn/b007885e5b4f4d9f84e3f4f215f3075a.png)
<center>方块有效值区域</center>
<br/>
<br/>

![在这里插入图片描述](https://img-blog.csdnimg.cn/ab68f3f7bf7b4beda0ca40681a2624f8.png)
<center>方块有效值区域</center>
<br/>
<br/>


>从方块有效值区域的仿真图可以看出，**横坐标的像素有效值区域**为 **41** 到 **1240**。HDMI 显示模块与我们编写的代码是一致的，下面就可以进行下载验证了。




<br/>
<br/>

# 5 下载验证


我们下载比特流`.bit`文件，验证 **HDMI 显示方块移动**的功能。下载完成后观察显示器显示的图案如下图所示， 图中的黑色方块能够不停的移动，且碰撞到蓝色边框时能改变移动方向，说明 HDMI 方块移动程序下载验证成功！


![在这里插入图片描述](https://img-blog.csdnimg.cn/00b174a2bf5c4139b0bd0c2cc17d9e37.png)





<br/>
<br/>



# 6 总结

本文主要是基于[《（七）零基础FPGA图像处理——HDMI彩条显示实验》](http://t.csdnimg.cn/TcfNH)进行了一个方块移动弹跳的实验， 通过本文的实验，相信您已经掌握了像素图像弹跳的方法。在实验中我们可以通过改变 **DIV_CNT** 参数改变方块弹跳的速度，**DIV_CNT** 的参数越大移动速度越慢，这个参数不是固定的，大家有兴趣可以自己尝试修改一下。



希望以上的内容对您有所帮助，**诚挚**地欢迎各位读者在评论区或者私信我交流！




微博：沂舟Ryan ([@沂舟Ryan 的个人主页 - 微博 ](https://weibo.com/u/7619968945))

GitHub：[ChinaRyan666](https://github.com/ChinaRyan666)

微信公众号：**沂舟无限进步**（内含精品资料及详细教程）

如果对您有帮助的话请点赞支持下吧！



**集中一点，登峰造极。**
