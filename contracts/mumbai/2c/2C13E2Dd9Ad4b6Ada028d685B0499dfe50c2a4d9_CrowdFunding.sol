// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract CrowdFunding {
    // constructor() {}

    struct Campaign {
        address raiser; // owner
        string title;
        string description;
        string image;
        uint256 target;
        uint256 deadline;
        uint256 amtFunded; // amountCollected
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(address => uint256) public addressToAmtFunded; // me

    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        string memory _image,
        uint256 _target,
        uint256 _deadline
    ) public returns (uint256) {
        require(
            _deadline < block.timestamp,
            "deadline must be date in future!"
        ); // me: làm vậy để kiểm biến trước?
        Campaign storage campaign = campaigns[numberOfCampaigns];
        // require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");  // lesson: cũng được
        // mang ý nghĩa khi load campaign lên thì ban đầu deadline sẽ =0 nên < block.timestamp?
        campaign.raiser = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amtFunded = 0;
        campaign.image = _image;

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        require(msg.value > 0, "donate value must > 0"); // me
        // uint256 amount = msg.value;  // dài dòng -> bỏ
        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);

        (bool sent, ) = payable(campaign.raiser).call{value: msg.value}("");
        if (sent) {
            campaign.amtFunded = campaign.amtFunded + msg.value;
            addressToAmtFunded[msg.sender] += msg.value; // me: tập rút gọn code
        }

        // có cần bổ sung thêm?
        // https://github.com/Cyfrin/foundry-full-course-f23#lesson-4-remix-fund-me
        // vì bài học chi tiết ở phần rút không phải gửi
    }

    // add handle situation when someone sends this contract native token without calling donateToCampaign()
    fallback() external {  // don't have payable because don't want to receive native token
        // donateToCampaign();  // không truyền id nên tắt luôn, cho revert
        // khả năng mở rộng: cho nhập id muốn donate ở bước kế
        revert();  // không nhận, trả lại
    }

    // receive() external payable {
    //     // donateToCampaign();  // không truyền id nên tắt luôn, cho revert
    //     revert();
    // }

    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns); // new Campaign[](numberOfCampaigns)  !!!, khởi tạo array với length là numberOfCampaigns
        for (uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i]; // fetch từng campaign trong campaigns chứ không phải phép gán thông thường (nói chung cú pháp solidity cần khai báo chặt chẽ)
            allCampaigns[i] = item;
        }
        return allCampaigns;
    }
}