/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// SPDX-License-Identifier: GPL-3.0
/**
 *
 * Cubix NFT holding rewards
 * URL: cubixpro.world/
 *
 */
pragma solidity >=0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}

interface ERC720 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function decimals() external view returns (uint8);
}

interface ERC721 {
    function totalSupply() external view returns (uint256 totalSupply);

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract CubixNFTHoldingRewards {
    using SafeMath for uint256;

    address ownerAddress;
    ERC720 token;
    uint256 public tokenDecimals;

    struct ClaimRequest {
        uint256 counter;
        address requester;
        uint256 time;
        bool isFullfiled;
    }
    uint256 counter;

    mapping(uint256 => ClaimRequest) public requests;
    mapping(address => ClaimRequest) public openRequests;
    mapping(address => uint256) public lastRequest;

    uint256 public deltaForNextRequest = 24 hours;
    bool public holdRequests = false;

    event ClaimRequested(
        uint256 counter,
        address requester,
        uint256 time,
        bool isFullfiled
    );
    event RewaredRequest(
        uint256 counter,
        address owner,
        uint256 amount,
        bool isValid,
        uint256 uptoDate
    );

    constructor(address _token) {
        token = ERC720(_token);
        ownerAddress = msg.sender;
        tokenDecimals = token.decimals();
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, 'Only owner');
        _;
    }

    function changeOwnerShip(address _owner) external onlyOwner {
        ownerAddress = _owner;
    }

    function changeDeltaForNextRequest(uint256 _hours) external onlyOwner {
        require(_hours > 0, "Hours should be greater than zero");
        deltaForNextRequest = _hours.mul(1 hours);
    }

    
    function changeHoldRequest(bool _holdRequests) external onlyOwner {
        holdRequests = _holdRequests;
    }

    function changeTokenAddress(address _token) external onlyOwner {
        token = ERC720(_token);
        tokenDecimals = token.decimals();
    }

    function contractCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function requestClaim() external {
        require(!holdRequests, "Requests are on hold");
        if (lastRequest[msg.sender] != 0) {
            require(lastRequest[msg.sender] < block.timestamp, "Cant place request as of now");
        }

        // if any unattended request is there
        openRequests[msg.sender].requester = address(0);
        
        require(
            openRequests[msg.sender].requester == address(0),
            'There is already open request for claim'
        );

        counter = counter.add(1);
        requests[counter] = ClaimRequest(
            counter,
            msg.sender,
            block.timestamp,
            false
        );
        openRequests[msg.sender] = requests[counter];
        lastRequest[msg.sender] = block.timestamp.add(deltaForNextRequest);
        emit ClaimRequested(
            counter,
            requests[counter].requester,
            requests[counter].time,
            requests[counter].isFullfiled
        );
    }

    function claim(
        address _address,
        uint256 amount,
        bool isValid,
        uint256 uptoDate
    ) external onlyOwner {
        require(
            openRequests[_address].requester != address(0),
            'There is no claim request pending'
        );
        if (isValid) {
            token.transfer(_address, amount);
        }
        emit RewaredRequest(
            openRequests[_address].counter,
            openRequests[_address].requester,
            amount,
            isValid,
            uptoDate
        );
        openRequests[_address] = ClaimRequest(
            0,
            address(0),
            0,
            false
        );
    }

    function retainUnsedCubix(uint256 amount) external onlyOwner {
        token.transfer(ownerAddress, amount);
    }
}