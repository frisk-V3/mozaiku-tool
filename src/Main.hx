import hx.widgets.*;
import haxe.io.Bytes;
import sys.io.File;

class Main extends App {
    var frame:Frame;
    var bmp:Image;          // wxImage
    var bmpCtrl:StaticBitmap;
    var pixelData:Array<Int>;
    var w:Int;
    var h:Int;

    static function main() {
        new Main();
    }

    override function onInit() {
        frame = new Frame(null, "Image Filter (Haxe + C++)");
        var panel = new Panel(frame);

        var btnLoad = new Button(panel, "Load Image");
        var btnGray = new Button(panel, "Grayscale");
        var btnMosaic = new Button(panel, "Mosaic");

        btnLoad.move(10,10);
        btnGray.move(120,10);
        btnMosaic.move(230,10);

        btnLoad.bind(EventType.BUTTON, _ -> loadImage());
        btnGray.bind(EventType.BUTTON, _ -> applyGray());
        btnMosaic.bind(EventType.BUTTON, _ -> applyMosaic());

        bmpCtrl = new StaticBitmap(panel, null, 10, 50);

        frame.resize(800,600);
        frame.show();
    }

    function loadImage() {
        var dlg = new FileDialog(frame, "Open", "", "", "*.png;*.jpg", FileDialogStyle.OPEN);
        if (dlg.showModal() == DialogID.OK) {
            bmp = new Image(dlg.path);
            w = bmp.width;
            h = bmp.height;

            // wxImage → RGBA Int[]
            pixelData = [];
            var bytes = bmp.data;
            for (i in 0...w*h) {
                var r = bytes.get(i*3);
                var g = bytes.get(i*3+1);
                var b = bytes.get(i*3+2);
                pixelData.push((0xFF<<24) | (r<<16) | (g<<8) | b);
            }

            updateBitmap();
        }
    }

    function updateBitmap() {
        // RGBA Int[] → wxImage
        var bytes = Bytes.alloc(w*h*3);
        for (i in 0...w*h) {
            var c = pixelData[i];
            bytes.set(i*3,   (c>>16)&0xFF);
            bytes.set(i*3+1, (c>>8)&0xFF);
            bytes.set(i*3+2, c&0xFF);
        }
        bmp = new Image(w, h, bytes, false);
        bmpCtrl.setBitmap(new Bitmap(bmp));
    }

    // -------------------------
    //  白黒フィルタ
    // -------------------------
    function applyGray() {
        for (i in 0...w*h) {
            var c = pixelData[i];
            var r = (c>>16)&0xFF;
            var g = (c>>8)&0xFF;
            var b = c&0xFF;
            var a = (c>>24)&0xFF;

            var gray = Std.int(r*299 + g*587 + b*114) / 1000;
            pixelData[i] = (a<<24) | (gray<<16) | (gray<<8) | gray;
        }
        updateBitmap();
    }

    // -------------------------
    //  モザイクフィルタ
    // -------------------------
    function applyMosaic(block:Int = 10) {
        for (y in 0...h step block) {
            for (x in 0...w step block) {
                var sumR = 0, sumG = 0, sumB = 0, sumA = 0;
                var count = 0;

                for (yy in y...Std.int(Math.min(y+block, h))) {
                    for (xx in x...Std.int(Math.min(x+block, w))) {
                        var c = pixelData[yy*w + xx];
                        sumR += (c>>16)&0xFF;
                        sumG += (c>>8)&0xFF;
                        sumB += c&0xFF;
                        sumA += (c>>24)&0xFF;
                        count++;
                    }
                }

                var r = Std.int(sumR / count);
                var g = Std.int(sumG / count);
                var b = Std.int(sumB / count);
                var a = Std.int(sumA / count);
                var avg = (a<<24)|(r<<16)|(g<<8)|b;

                for (yy in y...Std.int(Math.min(y+block, h))) {
                    for (xx in x...Std.int(Math.min(x+block, w))) {
                        pixelData[yy*w + xx] = avg;
                    }
                }
            }
        }
        updateBitmap();
    }
}
