//
//  Shader.fsh
//  teststoryboard
//
//  Created by Joshua Jensen on 2/24/17.
//  Copyright © 2017 Joshua Jensen. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
