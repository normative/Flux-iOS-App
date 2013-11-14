
varying lowp vec2 ttmp;
varying highp vec4 texCoordVarying[8];
uniform sampler2D textureSampler[8];
uniform highp mat4 textureModelMatrix;
uniform int renderEnable[8];
uniform lowp float topcrop;
uniform lowp float bottomcrop;
void main()
{
    lowp vec2  ttemp;
    highp vec4 resultVec;
    highp vec4 tempVec;
    ttemp = ttmp;
    int flag =0;
    highp vec3 background;
    highp vec3 foreground;
    highp vec3 transparent;
    highp float alpha;
    highp vec2 projCoord;
    
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
                background = gl_FragColor.rgb;
                
            }
        }
        
    }
    
    projCoord = texCoordVarying[0].st/ texCoordVarying[0].q;
    if((renderEnable[0]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[0].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            alpha = texture2D(textureSampler[5], projCoord).a;
            foreground = vec3(texture2D(textureSampler[0], projCoord).rgb);
            transparent = (1.0 -alpha)*background + alpha*foreground;
            background = transparent;
            gl_FragColor = vec4(transparent.rgb, 1.0);
            
        }
        
    }
    
    projCoord = texCoordVarying[1].st/ texCoordVarying[1].q;
    if((renderEnable[1]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[1].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            alpha = texture2D(textureSampler[5], projCoord).a;
            foreground = vec3(texture2D(textureSampler[0], projCoord).rgb);
            transparent = (1.0 -alpha)*background + alpha*foreground;
            background = transparent;
            gl_FragColor = vec4(transparent.rgb, 1.0);
        }
        
    }

    projCoord = texCoordVarying[2].st/ texCoordVarying[2].q;
    if((renderEnable[2]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[2].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            alpha = texture2D(textureSampler[5], projCoord).a;
            foreground = vec3(texture2D(textureSampler[0], projCoord).rgb);
            transparent = (1.0 -alpha)*background + alpha*foreground;
            background = transparent;
            gl_FragColor = vec4(transparent.rgb, 1.0);
        }
            
        
    }
    
    projCoord = texCoordVarying[3].st/ texCoordVarying[3].q;
    if((renderEnable[3]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[3].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            alpha = texture2D(textureSampler[5], projCoord).a;
            foreground = vec3(texture2D(textureSampler[0], projCoord).rgb);
            transparent = (1.0 -alpha)*background + alpha*foreground;
            background = transparent;
            gl_FragColor = vec4(transparent.rgb, 1.0);
           
        }
        
    }
    projCoord = texCoordVarying[4].st/ texCoordVarying[4].q;
    if((renderEnable[4]==1) && projCoord.s <1.0 && projCoord.t <1.0 && texCoordVarying[4].q >0.0)
    {
        
        if(projCoord.s >0.0 && projCoord.t> 0.0)
        {
            alpha = texture2D(textureSampler[5], projCoord).a;
            foreground = vec3(texture2D(textureSampler[0], projCoord).rgb);
            transparent = (1.0 -alpha)*background + alpha*foreground;
            background = transparent;
            gl_FragColor = vec4(transparent.rgb, 1.0);
            
        }
    }
 }



