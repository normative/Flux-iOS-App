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

varying highp vec2 texCoordVarying;
uniform sampler2D textureSampler;
void main()
{
    gl_FragColor = vec4(texture2D(textureSampler, texCoordVarying.st).rgb, 1.0);
}



