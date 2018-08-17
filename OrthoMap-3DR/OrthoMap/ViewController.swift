//
//  ViewController.swift
//  OrthoMap
//
//  Created by Andre on 7/5/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import UIKit
import Mapbox


class ViewController: UIViewController, MGLMapViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!  /** This is ImageView is for testing purposes */
    var postImage:UIImage?  /** The image that is posted to the mapView */
    var quadCoords:MGLCoordinateQuad?
    var orthoBuilder:OrthoImageBuilder!  /** The builder of the ortho view  */
    var mapView:MGLMapView!
    var orthoLayer: MGLStyleLayer?
    var orthoSource: MGLImageSource?
    var addIndex:Int = 1  /** IMPORTANT: For simulation purposes checks the timer index */
    let setName:String = "Set 3" /// NO SET 6
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        /** HOW THIS WORKS:
         
         - Images paths are loaded from a folder
         - An OrthoImageBuilder class is initialized with a certain amount of images
            ° OrthoImage objects are created as a result. These objects take the location, rotation, and image data from the path.
            ° The OrthoImageBuilder checks if the images are in proper rotation, if not it does not add them to the allData array, which is a public variable of the class.
            ° There is a cap that defines how many images are loaded before they can actually be added to create an image
            ° This cap is used for finding the GPS to Image point ratio before images are merged
            ° Once over images are added as usual
         - The timer adds images periodically to simulate a live feed

        */
        
        /** Loads all Image Paths into IMAGEDATA.all */
        configureImageData(imagePath: "/DemoImages/\(setName)")
        
        /** Initializes the OrthoBuilder with the first two images */
        orthoBuilder = OrthoImageBuilder(pathArray: [ IMAGEDATA.all[0], IMAGEDATA.all[1] ] )
        
        /** Starts a timer to add the Images every 0.5 seconds */
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(simulateOrtho), userInfo: nil, repeats: true)
        
        /** Finally sets up the mapView */
        setupMapView()
    }
    
    // MARK: - Sets the mapView settings
    func setupMapView() {
        mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.styleURL = MGLStyle.satelliteStyleURL
        mapView.setCenter(CLLocationCoordinate2D(latitude: 37.872581, longitude: -122.303236), zoomLevel: 17, animated: false)
        mapView.delegate = self
        view.addSubview(mapView)
    }
    
    
    // MARK: - Generates quad lat long points
    func generateQuadCoords(orthoBuilder:OrthoImageBuilder,mapView:MGLMapView) -> MGLCoordinateQuad {
        var bothLocations:[CLLocationCoordinate2D] = []
        var bothPixelPoints:[CGPoint] = []

        bothLocations.append( orthoBuilder.findBottomLeftImage().coordinates )
        bothLocations.append( orthoBuilder.findTopRightImage().coordinates )
        bothLocations.append( orthoBuilder.findTopLeftImage().coordinates )
        bothLocations.append( orthoBuilder.findBottomRightImage().coordinates )

        bothPixelPoints.append( orthoBuilder.findBottomLeftImage().point  )
        bothPixelPoints.append( orthoBuilder.findTopRightImage().point  )
        bothPixelPoints.append( orthoBuilder.findTopLeftImage().point )
        bothPixelPoints.append( orthoBuilder.findBottomRightImage().point )


        quadCoords = OrthoPlacerV2.calcImageCoordinates(map: mapView, geoPoints: bothLocations, pixelPoints: bothPixelPoints, imageSize: postImage!.size)

        return quadCoords!
    }

    
    
    // MARK: - Simulates the Ortho Building in real time
    @objc func simulateOrtho() {
        addIndex += 1
        if addIndex < IMAGEDATA.all.count { /** If the addIndex is less than the number of images stored then it adds a new Image to the Ortho */
            
            orthoBuilder.addImage( imagePath: IMAGEDATA.all[addIndex] )
            
            if orthoBuilder.allData.count > ORTHORATIO.numImages { /** ORTHORATIO.numImages is the cap for how many images we take ratios from */
                orthoBuilder.build()
                postImage = orthoBuilder.createImage()
                quadCoords = generateQuadCoords(orthoBuilder: self.orthoBuilder, mapView: self.mapView)
                self.addOverlay()
            }
        }
        else {
            
            for orthoImage in orthoBuilder.allData {
                
                //saveImageDocumentDirectory(image:orthoImage.getImage(),saveName: "\(setName) Image: \(orthoImage.id).jpg"  )
                
                
            }
            
            
            
        }
        
        
        
        
    }
    
    
    func saveImageDocumentDirectory(image:UIImage,saveName:String){
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(saveName)
        let image = image
        print(paths)
        let imageData = UIImageJPEGRepresentation(image, 0.5)
        fileManager.createFile(atPath: paths as String, contents: imageData, attributes: nil)
    }
    
    
    // MARK: - Loads all the images into IMAGEDATA.all
    func configureImageData(imagePath:String) {
        /** All images are stored in the Images folder, and are loaded through this method  */
        if let path = Bundle.main.resourcePath {
            let imagePath = path + imagePath
            let url = URL(fileURLWithPath: imagePath)
            let fileManager = FileManager.default
            let properties = [URLResourceKey.localizedNameKey,URLResourceKey.creationDateKey, URLResourceKey.localizedTypeDescriptionKey]
            do {
                let imageURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: properties, options:FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                
                for ( imageURL) in imageURLs {
                    
                    IMAGEDATA.all.append( imageURL.path )
                    
                }
                IMAGEDATA.all = IMAGEDATA.all.sorted {$0.localizedStandardCompare($1) == .orderedAscending} /** Images come in asnychronously, so must be organized in ascending order (The OrthoBuilder needs to know the appropriate next image) */
                
                
            } catch let error  {
                print(error)
            }
        }
    }
    

    // MARK: - Adds the Ortho Overlay to the map
    func addOverlay() {

        let coordinates = quadCoords!
        let sourceImage = postImage!
        
        /** Removes current layer and sources */
        if orthoLayer != nil && orthoSource != nil  {
            mapView.style!.removeLayer(orthoLayer!)
            mapView.style!.removeSource(orthoSource!)
        }
        
        /** Creates a new source, and new layer*/
        orthoSource = MGLImageSource(identifier: "\( arc4random()  )", coordinateQuad: coordinates, image: sourceImage )
        orthoLayer = MGLRasterStyleLayer(identifier: "\(arc4random()) - layer", source: orthoSource!)
        mapView.style!.addSource(orthoSource!)
        
        /** Adds the new layer under map marks */
        for layer in mapView.style!.layers.reversed() {
            if !layer.isKind(of: MGLSymbolStyleLayer.self) {
                mapView.style!.insertLayer(orthoLayer!, above: layer)
                break
            }
        }

    }




}

