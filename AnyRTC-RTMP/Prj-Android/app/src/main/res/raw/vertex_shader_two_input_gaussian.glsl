attribute vec4 aCamPosition;
attribute vec2 aCamTextureCoord;
attribute vec2 aImageTextureCoord;
varying vec2 vCamTextureCoord;
varying vec2 vImageTextureCoord;
void main(){
   gl_Position= aCamPosition;
   vCamTextureCoord = aCamTextureCoord;
   vImageTextureCoord = aImageTextureCoord;
}