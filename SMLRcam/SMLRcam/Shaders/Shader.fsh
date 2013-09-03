//
//  Shader.fsh
//  ImageViewer
//
//  Created by Arjun Chopra on 8/11/13.
//  Copyright (c) 2013 Arjun Chopra. All rights reserved.
//



varying highp vec2 tcoord;
uniform int special;
uniform sampler2D textureSampler[8];
//uniform highp mat4 textureModelMatrix;
void main()
{

          gl_FragColor = texture2D(textureSampler[0], tcoord.st).rgba;

}



