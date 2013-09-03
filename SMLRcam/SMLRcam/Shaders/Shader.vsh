//
//  Shader.vsh
//  ImageViewer
//
//  Created by Arjun Chopra on 8/11/13.
//  Copyright (c) 2013 Arjun Chopra. All rights reserved.
//

attribute vec4 position0;
attribute vec2 texCoord;
//varying lowp vec4 colorVarying;
varying highp  vec2 tcoord;


uniform mat4 modelViewProjectionMatrix;


void main()
{
    
    tcoord = texCoord;
    
    gl_Position = modelViewProjectionMatrix * vec4(position0.x, position0.y, position0.z, 1.0);
   // gl_Position = position0;
    
}
