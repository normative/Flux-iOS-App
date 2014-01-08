//
//  FluxMatcher.h
//  Flux
//
//  Created by Ryan Martens on 11/08/13.
//  Copyright (c) 2013 Ryan Martens. All rights reserved.
//

/*------------------------------------------------------------------------------------------*\
 This file contains material supporting chapter 9 of the cookbook:
 Computer Vision Programming using the OpenCV Library.
 by Robert Laganiere, Packt Publishing, 2011.
 
 This program is free software; permission is hereby granted to use, copy, modify,
 and distribute this source code, or portions thereof, for any purpose, without fee,
 subject to the restriction that the copyright notice may not be removed
 or altered from any source or altered source distribution.
 The software is released on an as-is basis and without any warranties of any kind.
 In particular, the software is not guaranteed to be fault-tolerant or free from failure.
 The author disclaims all warranties with regard to this software, any use,
 and any consequent failure, is purely the responsibility of the user.
 
 Copyright (C) 2010-2011 Robert Laganiere, www.laganiere.name
 \*------------------------------------------------------------------------------------------*/

#if !defined FLUXMATCHER
#define FLUXMATCHER

#include <opencv2/core/core.hpp>
#include <opencv2/calib3d/calib3d.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

class FluxMatcher {
    
private:
    
    // pointer to the feature point detector object
    cv::Ptr<cv::FeatureDetector> detector;
    // pointer to the feature descriptor extractor object
    cv::Ptr<cv::DescriptorExtractor> extractor;
    double ratio; // max ratio between 1st and 2nd NN
    bool refineF; // if true will refine the F matrix
    double distance; // min distance to epipolar
    double confidence; // confidence level (probability)
    
    bool doRatioTest;
    bool doAngleTest;
    bool doCrossCheckMatch;
    
public:
    
    FluxMatcher() : ratio(0.85f), refineF(true), confidence(0.99), distance(1.0),
                        doRatioTest(true), doAngleTest(true), doCrossCheckMatch(false)
    {
        int pyramid_levels = 3;
        int threshold_val = 40;
        bool useBRISKRotation = true;

        // Configure the feature detector

        detector = cv::FeatureDetector::create("FAST");
        detector->set("threshold", threshold_val);
        
        if (pyramid_levels > 0)
        {
            cv::Ptr<cv::FeatureDetector> base_detector = detector;
            detector = new cv::PyramidAdaptedFeatureDetector(detector, pyramid_levels);
        }
        
        // Configure the descriptor extractor
        
        extractor = cv::DescriptorExtractor::create("BRISK");
        
        if (useBRISKRotation)
        {
            extractor->set("rot_desc", 1);
        }
    }
    
    // Set the feature detector
    void setFeatureDetector(cv::Ptr<cv::FeatureDetector>& detect)
    {
        detector = detect;
    }
    
    // Set descriptor extractor
    void setDescriptorExtractor(cv::Ptr<cv::DescriptorExtractor>& desc)
    {
        extractor = desc;
    }
    
    // Set the minimum distance to epipolar in RANSAC
    void setMinDistanceToEpipolar(double d)
    {
        distance = d;
    }
    
    // Set confidence level in RANSAC
    void setConfidenceLevel(double c)
    {
        confidence = c;
    }
    
    // Set the NN ratio
    void setRatio(double r)
    {
        ratio = r;
    }
    
    // Set whether or not to do the ratio test
    void setRatioTest(bool doRatio)
    {
        doRatioTest = doRatio;
    }
    
    // Set whether or not to do the angle test
    void setAngleTest(bool doAngle)
    {
        doAngleTest = doAngle;
    }
    
    // Set whether or not to do use cross-checked matching instead of knn + others
    void setCrossCheckMatching(bool doCCMatch)
    {
        doCrossCheckMatch = doCCMatch;
    }

    // Get the minimum distance to epipolar in RANSAC
    double getMinDistanceToEpipolar()
    {
        return distance;
    }
    
    // Get confidence level in RANSAC
    double getConfidenceLevel()
    {
        return confidence;
    }
    
    // Get the NN ratio
    float getRatio()
    {
        return ratio;
    }
    
    // if you want the F matrix to be recalculated
    void refineFundamental(bool flag)
    {
        refineF = flag;
    }
    
    // Clear matches for which NN ratio is > than threshold
    // return the number of removed points
    // (corresponding entries being cleared, i.e. size will be 0)
    int ratioTest(std::vector<std::vector<cv::DMatch> >& matches);
    
    // Insert symmetrical matches in symMatches vector
    void symmetryTest(const std::vector<std::vector<cv::DMatch> >& matches1,
                      const std::vector<std::vector<cv::DMatch> >& matches2,
                      std::vector<cv::DMatch>& symMatches);
    
    // Return matches for which difference in angle between two matched keypoints is > than threshold
    void angleTest(const std::vector<cv::DMatch>& matches,
                   const std::vector<cv::KeyPoint>& keypoints1,
                   const std::vector<cv::KeyPoint>& keypoints2,
                   std::vector<cv::DMatch>& outMatches);
    
    // Identify good matches using RANSAC
    // outputs matches and fundemental matrix
    // returns 0 for success, negative if error
    int ransacTest(const std::vector<cv::DMatch>& matches,
                       const std::vector<cv::KeyPoint>& keypoints1,
                       const std::vector<cv::KeyPoint>& keypoints2,
                       std::vector<cv::DMatch>& outMatches,
                       cv::Mat& fundamental);
    
    // Match feature points using symmetry test and RANSAC
    // outputs matches and fundemental matrix
    // returns 0 for success, negative if error
    int match(std::vector<cv::DMatch>& matches, // output matches
              std::vector<cv::KeyPoint>& keypoints1, // keypoints1/descriptors1 are input for object image (image1)
              std::vector<cv::KeyPoint>& keypoints2, // keypoints2/descriptors2 are input for scene image (image2)
              cv::Mat& descriptors1, cv::Mat& descriptors2,
              cv::Mat& fundamental);
    
    // Detect and extract keypoints and descriptors on input image
    // returns 0 for success, negative if error
    int extractFeatures(cv::Mat& image,                         // input image
                        std::vector<cv::KeyPoint>& keypoints,   // output keypoints
                        cv::Mat& descriptors);                  // output feature descriptors

};

#endif
