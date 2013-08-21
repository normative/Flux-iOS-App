//
//  Shader.vsh
//  ImageViewer
//
//  Created by Arjun Chopra on 8/11/13.
//  Copyright (c) 2013 Arjun Chopra. All rights reserved.
//
/*
attribute vec3 position;
//attribute vec3 normal;//ac these will be the texture coordinates

attribute vec2 texCoord;

uniform mat4 modelViewProjectionMatrix;
//uniform mat3 normalMatrix;
uniform mat4 tBiasMVP;

varying highp vec4 TexCoord;

//uniform mat4 tBiasMVP1;
//uniform mat4 tBiasMVP2;

void main()
{

    //vec3 eyeNormal = normalize(normalMatrix * normal);
    //vec3 lightPosition = vec3(0.0, 0.0, 1.0);
    //vec4 diffuseColor = vec4(0.4, 0.4, 1.0, 1.0);
    
    //float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
                 
    //colorVarying = diffuseColor * nDotVP;
    
    gl_Position = modelViewProjectionMatrix * vec4(position.x, position.y, position.z, 1.0);


    
     TexCoord =  tBiasMVP  * vec4(position.x, position.y, position.z, 1.0);
    
    // TexCoord1 = tBiasMVP1 * position;
    // TexCoord2 = tBiasMVP2 * position;
    




}
*/

attribute vec4 position;
attribute vec2 texCoord;
//varying lowp vec4 colorVarying;

varying highp vec2 texCoordVarying;

uniform mat4 modelViewProjectionMatrix;


void main()
{
    
    texCoordVarying = texCoord;
    gl_Position = modelViewProjectionMatrix * position;
}
