// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract App{

    enum CourseStatus {
        NOT_STARTED,
        IN_PROGRESS,
        COMPLETED
    }

    enum CourseModuleStatus {
        NOT_STARTED,
        IN_PROGRESS,
        COMPLETED
    }

    enum RewardStatus {
        RECEIVED,
        NOT_RECEIVED,
        ERROR
    }

    mapping(uint256 => ContentCreator_Course[]) courses;    // contentCreatorId-coursesList
    mapping(uint256 => ContentCreator_CourseModule[]) modules;    // courseId-courseModulesList
    mapping(uint256 => LearnerCourseStatus[]) courseStatus;    // learnerId-courseStatusList
    mapping(uint256 => LearnerCourseModuleStatus[]) moduleStatus;    // learnerCourseId-courseModuleStatusList
    mapping(uint256 => uint256[]) contentCreator_learnersList;  // content creator's learner list
    mapping(uint256 => uint256[]) learner_contentCreatorList;   // learner's content creator list

    struct ContentCreator_Course{
        uint256 id;
        uint256 contentCreatorId;
        string name;
        string description;
        uint8 price;
        string topic;
        uint8 totalRating;
        uint8 ratingCount;
        uint256 creationDate;
    }

    struct ContentCreator_CourseModule{
        uint256 id;
        uint256 contentCreatorCourseId;
        string name;
        string description;
        string videoURL;
        string videoLength;
        string questionnaireURL;
        uint8 rewardPrice;
        uint8 rewardValidity;
        uint8 maxAttempts;
        uint256 creationDate;
    }

    struct LearnerCourseStatus{
        uint256 id;
        uint256 learnerId;
        uint256 courseId;
        CourseStatus courseStatus;
        bool isRatingProvided;
        uint256 startDate;
        uint256 endDate;
        uint256 purchaseDate;
    }

    struct LearnerCourseModuleStatus{
        uint256 id;
        uint256 learnerId;
        uint256 learnerCourseStatusId;
        CourseModuleStatus courseModuleStatus;
        uint8 attempts;
        uint8 rewardPrice;
        uint8 yourRewardPrice;
        RewardStatus rewardStatus;
        bool completedOnTime;
        uint256 startDate;
        uint256 endDate;
    }

    function createCourse(uint256 pContentCreatorId, 
                            string memory pName,
                            string memory pDescription,
                            uint8 pPrice,
                            string memory pTopic,
                            uint256 pCreationDate) public returns(bool){

        //uint256 initialCoursesLength = courses[pContentCreatorId].length;
        ContentCreator_Course[] memory ccCourses = courses[pContentCreatorId];
        uint256 courseIndex = ccCourses.length + 1;
        ContentCreator_Course memory newCourse = ContentCreator_Course({
            id: courseIndex,
            contentCreatorId: pContentCreatorId,
            name: pName,
            description: pDescription,
            price: pPrice,
            topic: pTopic,
            totalRating: 0,
            ratingCount: 0,
            creationDate: pCreationDate
        });
        courses[pContentCreatorId].push(newCourse);

        //return (initialCoursesLength != courses[pContentCreatorId].length);
        return true;
    }

    function getCourses(uint256 pContentCreatorId) public view returns(ContentCreator_Course[] memory ccCourse){
        return courses[pContentCreatorId];
    }
}