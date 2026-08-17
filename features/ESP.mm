#import "ESP.h"
#import "../AtlasMod.h"

bool g_ESPLine     = false;
bool g_ESPBox      = false;
bool g_ESPSkeleton = false;

// Bone pairs untuk skeleton ESP
static const int SKELETON[][2] = {
    {4,3},{3,1},{1,2},{2,5},{5,6},  // spine + arms
    {1,8},{8,9},{9,10},              // left leg
    {1,11},{11,12},{12,13}           // right leg
};

static CGPoint w2s(Vec3 pos, Matrix4x4 vp) {
    // sama macam dalam aimbot — reuse
    float cx = pos.x*vp.m[0][0]+pos.y*vp.m[1][0]+pos.z*vp.m[2][0]+vp.m[3][0];
    float cy = pos.x*vp.m[0][1]+pos.y*vp.m[1][1]+pos.z*vp.m[2][1]+vp.m[3][1];
    float cw = pos.x*vp.m[0][3]+pos.y*vp.m[1][3]+pos.z*vp.m[2][3]+vp.m[3][3];
    if(cw<=0) return CGPointZero;
    CGSize s = UIScreen.mainScreen.bounds.size;
    return CGPointMake((1+cx/cw)*s.width*.5f,(1-cy/cw)*s.height*.5f);
}

void ESP_Draw(CGContextRef ctx, uintptr_t* enemies,
              int count, Matrix4x4 vp) {
    CGContextSetLineWidth(ctx, 1.5f);
    CGSize screen = UIScreen.mainScreen.bounds.size;
    CGPoint myCenter = CGPointMake(screen.width/2, screen.height);
    
    for(int i=0;i<count;i++){
        if(!enemies[i]) continue;
        
        // ESP Line
        if(g_ESPLine){
            Vec3 foot = {0,0,0};
            memcpy(&foot,(void*)(*(uintptr_t*)(enemies[i]+0x138)+1*0x30),sizeof(Vec3));
            CGPoint fp = w2s(foot,vp);
            if(!CGPointEqualToPoint(fp,CGPointZero)){
                CGContextSetRGBStrokeColor(ctx,1,0,0,1);
                CGContextMoveToPoint(ctx,myCenter.x,myCenter.y);
                CGContextAddLineToPoint(ctx,fp.x,fp.y);
                CGContextStrokePath(ctx);
            }
        }
        
        // ESP Box
        if(g_ESPBox){
            Vec3 head={0,0,0},foot={0,0,0};
            uintptr_t bones=*(uintptr_t*)(enemies[i]+0x138);
            memcpy(&head,(void*)(bones+4*0x30),sizeof(Vec3));
            memcpy(&foot,(void*)(bones+7*0x30),sizeof(Vec3));
            CGPoint hp=w2s(head,vp),fp=w2s(foot,vp);
            if(!CGPointEqualToPoint(hp,CGPointZero)&&!CGPointEqualToPoint(fp,CGPointZero)){
                float h=fp.y-hp.y;
                float w=h*0.4f;
                CGRect box=CGRectMake(hp.x-w/2,hp.y,w,h);
                CGContextSetRGBStrokeColor(ctx,0,1,0,1);
                CGContextStrokeRect(ctx,box);
            }
        }
        
        // Skeleton
        if(g_ESPSkeleton){
            uintptr_t bones=*(uintptr_t*)(enemies[i]+0x138);
            CGContextSetRGBStrokeColor(ctx,1,1,0,1);
            int pairs=sizeof(SKELETON)/(sizeof(int)*2);
            for(int p=0;p<pairs;p++){
                Vec3 b1={0,0,0},b2={0,0,0};
                memcpy(&b1,(void*)(bones+SKELETON[p][0]*0x30),sizeof(Vec3));
                memcpy(&b2,(void*)(bones+SKELETON[p][1]*0x30),sizeof(Vec3));
                CGPoint p1=w2s(b1,vp),p2=w2s(b2,vp);
                if(CGPointEqualToPoint(p1,CGPointZero)||CGPointEqualToPoint(p2,CGPointZero)) continue;
                CGContextMoveToPoint(ctx,p1.x,p1.y);
                CGContextAddLineToPoint(ctx,p2.x,p2.y);
                CGContextStrokePath(ctx);
            }
        }
    }
}
