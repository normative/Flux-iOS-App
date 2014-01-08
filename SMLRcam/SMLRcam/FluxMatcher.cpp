//
//  FluxMatcher.mm
//  Flux
//
//  Created by Ryan Martens on 11/08/13.
//  Copyright (c) 2013 Ryan Martens. All rights reserved.
//

#include "FluxMatcher.h"


// Clear matches for which NN ratio is > than threshold
// return the number of removed points
// (corresponding entries being cleared, i.e. size will be 0)
int FluxMatcher::ratioTest(std::vector<std::vector<cv::DMatch> >& matches)
{
    int removed = 0;
   
    // for all matches
    for (std::vector<std::vector<cv::DMatch> >::iterator matchIterator= matches.begin();
         matchIterator!= matches.end(); ++matchIterator)
    {
        // if 2 NN has been identified
        if (matchIterator->size() > 1)
        {
            // check distance ratio
            if ((*matchIterator)[0].distance/(*matchIterator)[1].distance > ratio)
            {
                matchIterator->clear(); // remove match
                removed++;
            }
            
        }
        else
        {
            // does not have 2 neighbours
            matchIterator->clear(); // remove match
            removed++;
        }
    }
    
    return removed;
}

// Insert symmetrical matches in symMatches vector
void FluxMatcher::symmetryTest(
                                 const std::vector<std::vector<cv::DMatch> >& matches1,
                                 const std::vector<std::vector<cv::DMatch> >& matches2,
                                 std::vector<cv::DMatch>& symMatches)
{
    // for all matches image 1 -> image 2
    for (std::vector<std::vector<cv::DMatch> >::const_iterator matchIterator1= matches1.begin();
         matchIterator1!= matches1.end(); ++matchIterator1)
    {
        if (matchIterator1->size() < 2) // ignore deleted matches
            continue;
        
        // for all matches image 2 -> image 1
        for (std::vector<std::vector<cv::DMatch> >::const_iterator matchIterator2= matches2.begin();
             matchIterator2!= matches2.end(); ++matchIterator2)
        {
            if (matchIterator2->size() < 2) // ignore deleted matches
                continue;
            
            // Match symmetry test
            if ((*matchIterator1)[0].queryIdx == (*matchIterator2)[0].trainIdx  &&
                (*matchIterator2)[0].queryIdx == (*matchIterator1)[0].trainIdx)
            {
                // add symmetrical match
                symMatches.push_back(cv::DMatch((*matchIterator1)[0].queryIdx,
                                                (*matchIterator1)[0].trainIdx,
                                                (*matchIterator1)[0].distance));
                break; // next match in image 1 -> image 2
            }
        }
    }
}

// Return matches for which difference in angle between two matched keypoints is > than threshold
void FluxMatcher::angleTest(const std::vector<cv::DMatch>& matches,
                              const std::vector<cv::KeyPoint>& keypoints1,
                              const std::vector<cv::KeyPoint>& keypoints2,
                              std::vector<cv::DMatch>& outMatches)
{
    // for all matches
    for (std::vector<cv::DMatch>::const_iterator it = matches.begin();
         it != matches.end(); ++it)
    {
        float angle1 = keypoints1[it->queryIdx].angle;
        float angle2 = keypoints2[it->trainIdx].angle;
        if (abs(angle1 - angle2) < 20.0f)
        {
            outMatches.push_back(*it);
        }
    }
}

int FluxMatcher::ransacTest(const std::vector<cv::DMatch>& matches,
                                  const std::vector<cv::KeyPoint>& keypoints1,
                                  const std::vector<cv::KeyPoint>& keypoints2,
                                  std::vector<cv::DMatch>& outMatches,
                                  cv::Mat& fundamental)
{
    // Convert keypoints into Point2f
    std::vector<cv::Point2f> points1, points2;
    for (std::vector<cv::DMatch>::const_iterator it = matches.begin();
         it != matches.end(); ++it)
    {
        // Get the position of left keypoints
        float x= keypoints1[it->queryIdx].pt.x;
        float y= keypoints1[it->queryIdx].pt.y;
        points1.push_back(cv::Point2f(x,y));
        // Get the position of right keypoints
        x= keypoints2[it->trainIdx].pt.x;
        y= keypoints2[it->trainIdx].pt.y;
        points2.push_back(cv::Point2f(x,y));
    }
    
    // Compute F matrix using RANSAC
    std::vector<uchar> inliers(points1.size(),0);
    cv::Mat fundemental = cv::findFundamentalMat(
                                                cv::Mat(points1),cv::Mat(points2), // matching points
                                                inliers,      // match status (inlier or outlier)
                                                CV_FM_RANSAC, // RANSAC method
                                                distance,     // distance to epipolar line
                                                confidence);  // confidence probability
    
    // extract the surviving (inliers) matches
    std::vector<uchar>::const_iterator itIn = inliers.begin();
    std::vector<cv::DMatch>::const_iterator itM = matches.begin();
    // for all matches
    for ( ; itIn != inliers.end(); ++itIn, ++itM)
    {
        if (*itIn)
        {
            // it is a valid match
            outMatches.push_back(*itM);
        }
    }
    
    if (outMatches.size() <= 7)
    {
        return -1;
    }
    
    if (refineF)
    {
        // The F matrix will be recomputed with all accepted matches
        
        // Convert keypoints into Point2f for final F computation
        points1.clear();
        points2.clear();
        
        for (std::vector<cv::DMatch>::const_iterator it= outMatches.begin();
             it!= outMatches.end(); ++it)
        {
            // Get the position of left keypoints
            float x= keypoints1[it->queryIdx].pt.x;
            float y= keypoints1[it->queryIdx].pt.y;
            points1.push_back(cv::Point2f(x,y));
            // Get the position of right keypoints
            x= keypoints2[it->trainIdx].pt.x;
            y= keypoints2[it->trainIdx].pt.y;
            points2.push_back(cv::Point2f(x,y));
        }
        
        // Compute 8-point F from all accepted matches
        fundemental= cv::findFundamentalMat(
                                            cv::Mat(points1),cv::Mat(points2), // matching points
                                            CV_FM_8POINT); // 8-point method
    }
    
    return 0;
}

int FluxMatcher::match(std::vector<cv::DMatch>& matches, // output matches
                       std::vector<cv::KeyPoint>& keypoints1, // keypoints1/descriptors1 are input for object image (image1)
                       std::vector<cv::KeyPoint>& keypoints2, // keypoints2/descriptors2 are output/calculated from scene image (image2)
                       cv::Mat& descriptors1, cv::Mat& descriptors2,
                       cv::Mat& fundamental)
{
    // Verify descriptors exist for object and scene
    if (descriptors1.rows == 0 || descriptors2.rows == 0)
    {
        return -1;
    }
    
    // 2. Match the two image descriptors
    
    // Construction of the matcher
    cv::BFMatcher matcher;
    std::string descriptorName = extractor->name();
    if ((descriptorName.compare("Feature2D.SIFT") == 0) || (descriptorName.compare("Feature2D.SURF") == 0))
    {
        matcher = cv::BFMatcher(cv::NORM_L2, doCrossCheckMatch);
    }
    else
    {
        matcher = cv::BFMatcher(cv::NORM_HAMMING, doCrossCheckMatch);
    }

    std::vector<cv::DMatch> symMatches;

    if (doCrossCheckMatch)
    {
        matcher.match(descriptors1,descriptors2,
                      symMatches); // vector of matches (up to 2 per entry)
    }
    else
    {
        // from image 1 to image 2
        // based on k nearest neighbours (with k=2)
        std::vector<std::vector<cv::DMatch> > matches1;
        matcher.knnMatch(descriptors1,descriptors2,
                         matches1, // vector of matches (up to 2 per entry)
                         2);		  // return 2 nearest neighbours
        
        // from image 2 to image 1
        // based on k nearest neighbours (with k=2)
        std::vector<std::vector<cv::DMatch> > matches2;
        matcher.knnMatch(descriptors2,descriptors1,
                         matches2, // vector of matches (up to 2 per entry)
                         2);		  // return 2 nearest neighbours
        
        // 3. Remove matches for which NN ratio is > than threshold
        
        if (doRatioTest)
        {
            // clean image 1 -> image 2 matches
            int removed = ratioTest(matches1);
            
            // clean image 2 -> image 1 matches
            removed = ratioTest(matches2);
        }

        // 4. Remove non-symmetrical matches
        symmetryTest(matches1, matches2, symMatches);
    }
    
    // 5. Remove matches with differing angles
    std::vector<cv::DMatch> angleMatches;
    if (doAngleTest)
    {
        angleTest(symMatches, keypoints1, keypoints2, angleMatches);
    }
    else
    {
        angleMatches = symMatches;
    }
    
    if (angleMatches.size() > 7)
    {
        // 6. Validate matches using RANSAC
        if (ransacTest(angleMatches, keypoints1, keypoints2, matches, fundamental) < 0)
        {
            return -1;
        }
        
        return 0;
    }
    else
    {
        // No match found
        return -1;
    }
}

int FluxMatcher::extractFeatures(cv::Mat &image,                        // input image
                                 std::vector<cv::KeyPoint> &keypoints,  // output keypoints
                                 cv::Mat &descriptors)                  // output feature descriptors
{
    // 1a. Detection of the features
    detector->detect(image,keypoints);
    
    // 1b. Extraction of descriptors
    extractor->compute(image,keypoints,descriptors);
    
    if (descriptors.rows == 0)
    {
        return -1;
    }

    return 0;
}
