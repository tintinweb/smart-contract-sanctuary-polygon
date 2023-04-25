/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
/* OPEN QUESTIONS 
    1. Does there need to be a dedicated contribution address for each conversation?
    2. May be useful to have a mapping from conversation ID to convo metadata.
    3. Does all the conversatio metadata need to be stored in SC?
    4. Convo Array vs mapping (looks like best practice is separate for metadata)
    5. createDelegatedConvo (onlyOwner can create on behalf of an address)
    6. Separate gov address from revenue address
    7. Reentrancy guard on critical functions
*/

/// @title Core dLogos contract
/// @author Ankit Bhatia
contract dLogos {

    struct Backer {
        address addr;
        uint256 amount; // ETH Contribution
    }

    struct Speaker {
        address addr;
        uint16 fee; // Speaker reward BPS
    }

    struct Host {
        address addr;
        uint16 fee; // Host reward BPS
    }

    /// @notice All on-chain information for a Logo.
    struct Logo {
        // Meta
        uint256 id;
        string title;
        string description;
        string discussion;
    
        // Roles
        address creator;

        uint scheduledAt;

        // Crowdfunding Attributes
        uint crowdfundStartAt;
        uint crowdfundEndAt;
        bool isCrowdfunding;

        /*
        address[] speakers;
        address[] backers;      // BackerInfo[] backers;
    
        

        // Scheduling Attributes
        uint scheduledAt;
        uint scheduleFailedRefundAt; // Date to allow refund if conversation is not scheduled.
        bool isScheduled;
        
        // Media Upload Attributes
        uint uploadFailureRefundAt; // Date to allow refund if conversation is not uploaded.
        
        */
        string mediaAssetURL;
        bool isUploaded;
    }
    
    // Global Logo ID starting from 1
    uint256 public logoID = 1;
    // Mapping of Owner addresses to Logo ID to Logo info
    mapping(uint256 => Logo) public logos;
    // Mapping of Logo ID to list of Backers
    mapping(uint256 => Backer[]) public logoBackers;
    // Mapping of Logo ID to list of Speakers
    mapping(uint256 => Speaker[]) public logoSpeakers;
    // Mapping of Logo ID to list of Hosts
    mapping(uint256 => Host[]) public logoHosts;
    // dLogos fees in BPS (3%)
    uint16 public dLogosServiceFee = 300;

    /* Events */
    event LogUpdateFee(uint16 indexed _fee);
    event LogoCreated(address indexed _owner, uint indexed _logoID);
    event CrowdfundOpened(address indexed _owner, uint indexed _crowdfundStartAt, uint indexed _crowdfundEndAt);
    event Crowdfund(address indexed _owner, uint indexed _amount);
    event FundsWithdrawn(address indexed _owner, uint indexed _amount);
    event DateSet(address indexed _owner, uint indexed _scheduledAt);
    event MediaAssetLinked(address indexed _owner, string indexed _mediaAssetURL);


    function setServiceFee(uint16 _dLogosServiceFee) external {
        /* TODO: (1) onlyOwner */
        require(_dLogosServiceFee > 0 && _dLogosServiceFee <= 10000, "dLogos: DLOGOS_SERVICE_FEE_INVALID");
        dLogosServiceFee = _dLogosServiceFee;
        emit LogUpdateFee(dLogosServiceFee);
    }

    // Returns logoID
    function createLogo(
        string calldata _title,
        string calldata _description,
        string calldata _discussion,
        string calldata _mediaAssetURL
    ) external returns (uint256) {
        /* TODO: (1) Requires (2) right role */
        logos[logoID] = Logo({
            id: logoID,
            title: _title,
            description: _description,
            discussion: _discussion,
            creator: msg.sender,
            scheduledAt: 0, // TODO: Correct default
            mediaAssetURL: _mediaAssetURL,
            isUploaded: false,
            isCrowdfunding: false,
            crowdfundStartAt: 0,
            crowdfundEndAt: 0
        });

        emit LogoCreated(msg.sender, logoID);

        return logoID++; // Return and Increment Global Logo ID
    }

    /**
    * @dev Open crowdfund for Logo. Only the owner of the Logo is allowed to open a crowdfund.
    * returns if successful.
    */
    function openCrowdfund(
        uint256 _logoID,
        uint _crowdfundNumberOfDays
    ) external returns (bool) { 
        Logo memory l = logos[_logoID];
        // Todo: Add checks for _crowdfundNumberOfDays
        l.crowdfundStartAt = block.timestamp;
        l.crowdfundEndAt = block.timestamp + _crowdfundNumberOfDays * 1 days;
        l.isCrowdfunding = true;
        logos[_logoID] = l;

        emit CrowdfundOpened(msg.sender, l.crowdfundStartAt, l.crowdfundEndAt);

        return true;
    }

    function crowdfund(
        uint256 _logoID
    ) payable external {
        
        // TODO: Requires and Roles

        // Record the value sent to the address.
        Backer memory b = Backer({
            addr: msg.sender,
            amount: msg.value
        });

        logoBackers[_logoID].push(b);

        emit Crowdfund(msg.sender, msg.value);
        
    }

    // TODO: Reentrency
    /**
    * @dev Withdraw your pledge from a logo.
    */
    function withdrawFunds(
        uint256 _logoID,
        uint256 _amount 
    ) external {
        Backer[] storage backers = logoBackers[_logoID];

        for (uint i = 0; i < backers.length; i++){
            if (backers[i].addr == msg.sender && backers[i].amount == _amount){
                uint256 amount = backers[i].amount;
                (bool success, ) = payable(msg.sender).call{value : amount}("");
                require(success, "Transfer failed.");
                delete backers[i];
                emit FundsWithdrawn(msg.sender, amount);
                break;
            }
        }
        
    }

    /**
    * @dev Return the list of backers for a logo.
    */
    function getBackersForLogo(
        uint256 _logoID
    ) external view returns (Backer[] memory){
        return logoBackers[_logoID];
    }

    /**
    * @dev Return the list of convos for a creator.
    */
    // function getConvo(address _creator) external view returns(Convo[] memory) {
    //     return conversations[_creator][];
    // }

    /**
    * @dev Add speakers for a logo.
    */
    function addSpeakers(
        uint256 _logoID,
        address[] calldata _speakers,
        uint16[] calldata _fees
    ) external {
        Logo memory l = logos[_logoID];
        require(l.creator == msg.sender); // Require msg sender to be the creator
        require(_speakers.length == _fees.length); // Equal speakers and fees
        
        for (uint i = 0; i < _speakers.length; i++){
            Speaker memory s = Speaker({
                addr: _speakers[i],
                fee: _fees[i]
            });
            logoSpeakers[_logoID].push(s);
        }
    }

    /**
    * @dev Set date for a conversation.
    */
    function setDate(
        uint256 _logoID, 
        uint _scheduledAt
    ) external {

        Logo memory l = logos[_logoID];
        
        require(l.creator == msg.sender); // Require msg sender to be the creator
        
        l.scheduledAt = _scheduledAt;
        logos[_logoID] = l;

        emit DateSet(msg.sender, _scheduledAt);
    }

    /*
    * @dev Links media URl for a logo.
    * returns if link was successful
    */
    function linkMediaAsset(
        uint256 _logoID,
        string calldata _mediaAssetURL
    ) external {
        Logo memory l = logos[_logoID];

        require(l.creator == msg.sender); // Require msg sender to be the creator

        l.mediaAssetURL = _mediaAssetURL;
        logos[_logoID] = l; // add check prior to this

        emit MediaAssetLinked(msg.sender, _mediaAssetURL);
    }

    // function distributeRewards(
    //     uint256 _logoID
    // ) external returns (bool) {
    //     Logo memory l = logos[_logoID];
    //     require(l.creator == msg.sender); // Require msg sender to be the creator
        
    //     uint256 totalRewards = 0;
    //     Backer[] memory backers = logoBackers[_logoID];
    //     for (uint i = 0; i < backers.length; i++){
    //         totalRewards += backers[i].amount;
    //     }


    //     return true;
    // }

}