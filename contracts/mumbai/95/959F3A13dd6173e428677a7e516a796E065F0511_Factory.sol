/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

//SPDX-License-Identifier: UNLICENSED 

pragma solidity ^0.8.17;

/*
    * @author : Blockchain Lighthouse Team
    * @notice : Auction Factory Contract
*/
contract Auction {
    constructor(
        uint _auctionId, 
        string memory _ipfsPath, 
        address _seller, 
        address _bidder, 
        address _admin, 
        uint256 _maxPrice, 
        uint256 _createdAt, 
        uint256 _expiredAt
    ) payable {
        auctionId = _auctionId;
        ipfsPath = _ipfsPath;
        seller = _seller;
        bidders.push(Bidder(
            _bidder,
            msg.value,
            block.timestamp
        ));
        admin = _admin;
        maxPrice = _maxPrice;
        createdAt = _createdAt;
        expiredAt = _expiredAt;
    }

    /*
        DATA STRUCT
    */
    struct Bidder {
        address bidder;
        uint256 price;
        uint256 biddedAt;
    }

    Bidder[] public bidders;
    uint256 public auctionId;
    string public ipfsPath;
    address public seller;
    uint256 public maxPrice;
    uint256 public createdAt;
    uint256 public expiredAt;
    address public admin;
    bool public lock;

    /*
        Modifiers
    */
    modifier mutexGuard() {
        require(!lock, "ERR : CURRENTLY LOCKED");
        lock = true;
        _;
        lock = false;
    }

    receive() external payable {}

    /*
        EVENTS
    */
    event Bid(
        uint256 indexed auctionId,
        address indexed auctionContract, 
        address caller, 
        uint256 price, 
        uint256 occurredAt
    );
    
    event Withdrawal(
        uint256 indexed auctionId,
        address indexed auctionContract, 
        address caller, 
        uint256 price, 
        uint256 occurredAt
    );

    /*
     * @notice : Bidders Length
     * @caller : Anyone
     * @Returns : Length of Bidders;
    */
    function biddersLength() external view returns(uint256) {
        return bidders.length;
    }

    /*
     * @notice : Auction Bid Function;
     * @caller : Bidder
     * @value : Upper than current Price;
    */
    function bid() external payable mutexGuard {
        require(expiredAt >= block.timestamp, "AUCTION ENDED(TIME)");
        require(bidders[bidders.length-1].price != maxPrice, "AUCTION ENDED(PRICE REACHED)");
        require(msg.value > bidders[bidders.length-1].price, "ERR: Price Should be more than CurrentPrice");
        
        payable(bidders[bidders.length-1].bidder).transfer(bidders[bidders.length-1].price);

        bidders.push(Bidder(
            msg.sender,
            msg.value,
            block.timestamp
        ));

        emit Bid(
            auctionId,
            address(this), 
            msg.sender, 
            msg.value, 
            block.timestamp
        );
    }

    /*
     * @notice : Withdraw
     * @caller : Seller
     * @_message : signs Message
     * @_v : Sinature first 32 byte
     * @_r : Sinature second 32 byte
     * @_s : Sinature last bytes
    */
    function withdraw(bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external mutexGuard {
        address signer = _recoverSigner(_message, _v, _r, _s);
        require(bidders[bidders.length-1].bidder == signer || admin == signer, "ERR : INVALID SIGNATURE");
        require(msg.sender == seller, "ERR : ONLY SELLER");
        require(expiredAt <= block.timestamp || maxPrice <= bidders[bidders.length-1].price, "ERR : NOT AUTORIZED");

        payable(seller).transfer(address(this).balance);
        
        emit Withdrawal (
            auctionId,
            address(this),
            msg.sender,
            address(this).balance,
            block.timestamp
        );
    }

    /*
     * @notice : Withdraw when Accident
     * @caller : Only Who approved
     * @_message : signs Message
     * @_v : Sinature first 32 byte
     * @_r : Sinature second 32 byte
     * @_s : Sinature last bytes
    */
    function emergencyWithdraw(bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external mutexGuard {
        address signer = _recoverSigner(_message, _v, _r, _s);
        require(admin == signer, "ERR : INVALID SIGNATURE");
        require(expiredAt <= block.timestamp, "ERR : NOT AUTHORIZED");
        require(msg.sender == seller || msg.sender == bidders[bidders.length-1].bidder, "ERR : ONLY CONCERNED");
        require(_message == keccak256(abi.encodePacked(msg.sender)));
        
        payable(msg.sender).transfer(address(this).balance);
        
        emit Withdrawal (
            auctionId,
            address(this),
            msg.sender,
            address(this).balance,
            block.timestamp
        );
    }

    /*
     * @notice : Recover Signature
     * @caller : Internal
    */
    function _recoverSigner(bytes32 message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes32 prefixedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        return ecrecover(prefixedMessage, v, r, s);
    }
}

pragma solidity ^0.8.17;

/*
    * @author : Blockchain Lighthouse Team
    * @notice : Auction Factory Contract
*/
contract Factory {
    address public admin;
    bool public lock;
    uint256 public totalAuctions;

    struct AuctionTx {
        uint auctionId;
        address contractPath;
        string ipfsPath;
        address seller;
        uint initPrice;
        uint256 timestamp;
    } 

    constructor() {
        admin = msg.sender;
    }

    mapping(uint256 => AuctionTx) public auctionRecord; 

    modifier onlyAdmin() {
        require(msg.sender == admin, "ERR: Not Authorized");
        _;
    }

    modifier mutexGuard() {
        require(!lock, "ERR : CURRENTLY LOCKED");
        lock = true;
        _;
        lock = false;
    }

    event AuctionCreated(
        uint indexed auctionId,
        address auctionContract,
        address caller,
        uint256 price,
        uint256 occurredAt
    );

    /*
     * @notice : Create Auction Function;
     * @caller : First Bidder (Client)
     * @value : Minimum 0.1 MATIC required; (0.1 MATIC = 150 KRW <2023.03.30>)
     * @_auctionId : Auction Board ID (PK);
     * @_ipfsPath : Auction Detail Record on Ipfs URL Path;
     * @_seller : Auction Board Writer;
     * @_maxPrice : Immediately Buy Price;
     * @_expirationUinx : Expiration Time want to set of the auction; (Ex : 3600 => block.timestamp ± 3600, 1Hour)
    */
    function createAuction(
        uint256 _auctionId, 
        string memory _ipfsPath, 
        address _seller, 
        uint256 _maxPrice, 
        uint256 _expirationUinx
    ) external payable mutexGuard {
        require(msg.value >= 0.1 ether, "ERR: MINIMUM 0.1 MATIC");
        require(auctionRecord[_auctionId].contractPath == address(0), "ERR: AUCTION ALREADY EXIST");
        require(_seller != msg.sender, "ERR : SELLER COULD NOT BE BIDDER");
        // Create Auction Contract & Send msg.value; (No Commission);
        Auction newAuction = new Auction{
            value : msg.value
        }(
            _auctionId, 
            _ipfsPath, 
            _seller, 
            msg.sender, 
            admin, 
            _maxPrice * 10**18, 
            block.timestamp, 
            _expirationUinx
        );
  
        auctionRecord[_auctionId] = AuctionTx(
            _auctionId,
            address(newAuction),
            _ipfsPath,
            _seller,
            msg.value,
            block.timestamp
        );
        
        totalAuctions++;
        
        emit AuctionCreated(
            _auctionId,
            address(newAuction),
            msg.sender, 
            msg.value,
            block.timestamp
        );
    }

    /*
     * @notice : Change New Admin Function;
     * @caller : Original Admin;
     * @_newAdmin : New Admin Address;
    */
    function changeAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    /*
     * @notice : Emergency Stop;
     * @caller : Admin;
    */
    function emergencyStop() external onlyAdmin {
        lock = !lock;
    }
}