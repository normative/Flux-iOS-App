//
//  Shader.fsh
//  ImageViewer
//
//  Created by Arjun Chopra on 8/11/13.
//  Copyright (c) 2013 Arjun Chopra. All rights reserved.
//
/*

varying highp vec4 TexCoord;
uniform sampler2D myTextureSampler;

//varying vec4 TexCoord1;
//varying vec4 TexCoord2;


//uniform sampler2D myTextureSampler1;
//uniform sampler2D myTextureSampler2;

void main()
{
    
    //gl_FragColor = colorVarying;
    
   
    highp vec2 projCoord = TexCoord.st/ TexCoord.q;
    if(projCoord.s <1.0 && projCoord.t <1.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
            gl_FragColor = texture2D(myTextureSampler, projCoord);
        
    }
    else
   
        gl_FragColor =vec4(0.0, 0.0, 0.0, 0.0);
   
   // projCoord = TexCoord1.st/ TexCoord1.q;
   // if(projCoord.s <1.0 && projCoord.t <1.0)
   // {
        
     //   if(projCoord.s >0.0 && projCoord.t> 0.0)
       //     gl_FragColor = texture2D(myTextureSampler1, projCoord);
        
   // }
   // projCoord = TexCoord2.st/ TexCoord2.q;
   // if(projCoord.s <1.0 && projCoord.t <1.0)
   // {
        
   //     if(projCoord.s >0.0 && projCoord.t> 0.0)
     //       gl_FragColor = texture2D(myTextureSampler2, projCoord);
        
   // }
    
}
 */
/*

varying highp vec2 texCoordVarying;
uniform sampler2D textureSampler;
void main()
{
    gl_FragColor = vec4(texture2D(textureSampler, texCoordVarying.st).rgb, 1.0);
}
*/

varying lowp vec2 ttmp;
varying highp vec4 texCoordVarying[8];
uniform sampler2D textureSampler[8];
uniform highp mat4 textureModelMatrix;
uniform int renderEnable[8];
void main()
{
    lowp vec2  ttemp;
    highp vec4 resultVec;
    highp vec4 tempVec;
    ttemp = ttmp;
    int flag =0;
    highp vec2 projCoord = texCoordVarying[0].st/ texCoordVarying[0].q;
    if((renderEnable[0]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[0].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            gl_FragColor = vec4(texture2D(textureSampler[0], projCoord).rgb,1.0);
            flag = 1;
        }
        
    }
    
    projCoord = texCoordVarying[1].st/ texCoordVarying[1].q;
    if((renderEnable[1]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[1].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            gl_FragColor = vec4(texture2D(textureSampler[1], projCoord).rgb,1.0);
            flag =1;
        }
        
    }

    projCoord = texCoordVarying[2].st/ texCoordVarying[2].q;
    if((renderEnable[2]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[2].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            gl_FragColor = vec4(texture2D(textureSampler[2], projCoord).rgb,1.0);
            flag =1;
        }
            
        
    }
    
    projCoord = texCoordVarying[3].st/ texCoordVarying[3].q;
    if((renderEnable[3]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[3].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            gl_FragColor = vec4(texture2D(textureSampler[3], projCoord).rgb, 1.0);
            flag =1;
        }
        
    }
    projCoord = texCoordVarying[4].st/ texCoordVarying[4].q;
    if((renderEnable[4]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[4].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            gl_FragColor = vec4(texture2D(textureSampler[4], projCoord).rgb, 1.0);
            flag =1;
        }
    }
    
    if(flag==0)
    {
        projCoord = texCoordVarying[7].st/ texCoordVarying[7].q;
        if(projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[7].q >0.0)
        {
            
            if(projCoord.s >0.0 && projCoord.t> 0.0)
            {
                projCoord.t = 1.0 - projCoord.t;
               
                tempVec.x = -0.5 + projCoord.s;
                tempVec.y = -0.5 + projCoord.t;
                tempVec.z = 0.0;
                tempVec.w =1.0;
                
                
                
                resultVec = textureModelMatrix * tempVec;
                resultVec.x = 0.5 + resultVec.x;
                resultVec.y = 0.5 + resultVec.y;
                

                
                
                gl_FragColor = texture2D(textureSampler[7], resultVec.st).rgba;
                
            }
        }
       //gl_FragColor = texture2D(textureSampler[7], texCoordVarying[7].xy);
      // gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
    
   // gl_FragColor = texture2D(textureSampler[7], texCoordVarying.st).rgba;
}



