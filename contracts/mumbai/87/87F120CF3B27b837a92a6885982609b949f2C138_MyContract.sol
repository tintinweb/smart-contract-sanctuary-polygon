// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

contract MyContract {
    // only for taking input for function uploadAttendance
    struct uploadAttendanceHelper {
        string subject_id;
        string student_id;
        bool status;
        string remark;
        string date;
        string timestamp;
    }

    // Struct to store the attendance data
    struct AttendanceData {
        string date;
        string timestamp;
        bool status;
        string remark;
        uint256 record_id;
    }

    // Struct to store the attendance details
    struct AttendanceDetail {
        uint256 total_classes;
        uint256 classes_attended;
        //This is intended to keep count of total number of entries inside the student_attendance_data, which is used as the primary key for entries. This primary keys are used to update remarks.
        uint256 entry_count;
        AttendanceData[] student_attendance_data;
    }

    //subject_id => student_id => AttendanceDetail.
    mapping(string => mapping(string => AttendanceDetail))
        public attendanceRecord;

    //function to upload the attendance details into the block chain.
    function uploadAttendance(uploadAttendanceHelper[] memory _data) public {
        for (uint256 i; i < _data.length; i++) {
            uploadAttendanceHelper memory record = _data[i];

            AttendanceDetail storage tmp = attendanceRecord[record.subject_id][
                record.student_id
            ];

            //incrimenting total classes
            tmp.total_classes = tmp.total_classes + 1;
            //only incrimenting the classes attended if and only if record.status = true
            if (record.status == true) {
                tmp.classes_attended = tmp.classes_attended + 1;
            }

            //incrimenting the entry_count
            tmp.entry_count = tmp.entry_count + 1;

            tmp.student_attendance_data.push(
                AttendanceData(
                    record.date,
                    record.timestamp,
                    record.status,
                    record.remark,
                    tmp.entry_count
                )
            );
        }
    }

    // to fetch the student attendance details.
    function getStudentAttendanceDetail(
        string memory subject_id,
        string memory student_id
    ) public view returns (AttendanceDetail memory) {
        return attendanceRecord[subject_id][student_id];
    }

    // to update the remark.
    function updateRemark(
        string memory subject_id,
        string memory student_id,
        string memory _remark,
        uint256 _record_id
    ) public {
        AttendanceData[] storage records = attendanceRecord[subject_id][
            student_id
        ].student_attendance_data;
        for (uint256 i = 0; i < records.length; i++) {
            AttendanceData storage record = records[i];
            if (record.record_id == _record_id) {
                record.remark = _remark;
            }
        }
    }

    // to calculate and return attendance percentage.
    function getAttendancePercentage(
        string memory subject_id,
        string memory student_id
    ) public view returns (uint256) {
        uint256 totalNumberOfClasses = attendanceRecord[subject_id][student_id]
            .total_classes;
        uint256 numberOfClassesAttended = attendanceRecord[subject_id][
            student_id
        ].classes_attended;
        return (numberOfClassesAttended / totalNumberOfClasses) * 100;
    }

    // Struct to store the leave records
    // struct LeaveRecords {
    //     // url of the document uploaded in google drive or somewhere
    //     string url;
    //     string date;
    //     string timestamp;
    // }

    // // student_id => LeaveRecords[]
    // mapping(string => LeaveRecords[]) public leaveRecordsMap;

    // // function to add/update the leave records
    // function updateLeaveRecords(
    //     string memory url,
    //     string memory date,
    //     string memory timestamp,
    //     string memory student_id
    // ) public {
    //     LeaveRecords[] storage tmp = leaveRecordsMap[student_id];
    //     tmp.push(LeaveRecords(url, date, timestamp));
    // }

    // // function to retrieve leave records
    // function getLeaveRecords(
    //     string memory student_id
    // ) public view returns (LeaveRecords[] memory) {
    //     return leaveRecordsMap[student_id];
    // }

    // struct attendanceRecord {
    //     string date;
    //     string subject_id;
    //     string student_id;
    //     string timestamp;
    //     bool status;
    //     string log;
    //     uint256 classNumber;
    //     uint256 classPresent;
    // }
    // mapping(string => uint256) public numberOfClassesMap;

    // mapping(string => attendanceRecord[]) public subjectToAttendanceMap;

    // function uploadAttendance(attendanceRecord[] memory _data) public {
    //     numberOfClassesMap[_data[0].subject_id]++;

    //     for (uint256 i = 0; i < _data.length; i++) {
    //         attendanceRecord memory newRecord;
    //         newRecord.date = _data[i].date;
    //         newRecord.subject_id = _data[i].subject_id;
    //         newRecord.student_id = _data[i].student_id;
    //         newRecord.timestamp = _data[i].timestamp;
    //         newRecord.status = _data[i].status;
    //         newRecord.log = _data[i].log;
    //         newRecord.classNumber = numberOfClassesMap[_data[i].subject_id];
    //         //research is needed

    //         subjectToAttendanceMap[_data[i].subject_id].push(newRecord);
    //     }
    // }

    // function getRecords(
    //     string memory _subject_id
    // ) public view returns (attendanceRecord[] memory) {
    //     return subjectToAttendanceMap[_subject_id];
    // }

    // function getStudentAttendance(
    //     string memory subject_id,
    //     string memory _student_id
    // ) public view returns (attendanceRecord[] memory) {
    //     attendanceRecord[] memory record = subjectToAttendanceMap[subject_id];
    //     attendanceRecord[] memory student_record;
    //     uint256 j = 1;
    //     for (uint256 i = 0; i < record.length; i++) {
    //         if (
    //             keccak256(abi.encodePacked(record[i].student_id)) ==
    //             keccak256(abi.encodePacked(_student_id))
    //         ) {
    //             student_record[j] = record[i];
    //             j++;
    //         }
    //     }

    //     return student_record;
    // }

    // function writeLog(string memory student_id, string memory log) public {}

    // struct Campaign {
    //     address owner;
    //     string title;
    //     string description;
    //     uint256 target;
    //     uint256 deadline;
    //     uint256 amountCollected;
    //     string image;
    //     address[] donators;
    //     uint256[] donations;
    // }

    // mapping(uint256 => Campaign) public campaigns;

    // uint256 public numberOfCampaigns = 0;

    // function createCampaign(
    //     address _owner,
    //     string memory _title,
    //     string memory _description,
    //     uint256 _target,
    //     uint256 _deadline,
    //     string memory _image
    // ) public returns (uint256) {
    //     Campaign memory campaign;

    //     // is everything ok?
    //     require(
    //         campaign.deadline < block.timestamp,
    //         "The deadline should be in future"
    //     );

    //     campaign.owner = _owner;
    //     campaign.title = _title;
    //     campaign.description = _description;
    //     campaign.target = _target;
    //     campaign.deadline = _deadline;
    //     campaign.amountCollected = 0;
    //     campaign.image = _image;

    //     campaigns[numberOfCampaigns] = campaign;

    //     numberOfCampaigns++;

    //     return numberOfCampaigns - 1;
    // }

    // function donateCampaign(uint256 _id) public payable {
    //     uint256 amount = msg.value;

    //     Campaign storage campaign = campaigns[_id];

    //     campaign.donators.push(msg.sender);
    //     campaign.donations.push(amount);

    //     // payable(campaign.owner).transfer(amount);

    //     (bool sent, ) = campaign.owner.call{value: amount}("");

    //     if (sent) {
    //         campaign.amountCollected = campaign.amountCollected + amount;
    //     }
    //     campaign.amountCollected = campaign.amountCollected + amount;
    // }

    // function getDonators(
    //     uint256 _id
    // ) public view returns (address[] memory, uint256[] memory) {
    //     return (campaigns[_id].donators, campaigns[_id].donations);
    // }

    // function getCampaigns() public view returns (Campaign[] memory) {
    //     Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

    //     for (uint i = 0; i < numberOfCampaigns; i++) {
    //         Campaign storage item = campaigns[i];
    //         allCampaigns[i] = item;
    //     }

    //     return allCampaigns;
    // }
}