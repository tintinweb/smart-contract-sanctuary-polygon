pragma solidity ^0.8.0;

interface ITest {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Test {
    address public owner;

    constructor(){
        owner = tx.origin;
    }

    /*==============Event Test==============*/
    event LOG_USER_VAULT(address indexed vault, address indexed caller);
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);
    event FeedSet(address feed, string symbol);
    event NewAdmin(address oldAdmin, address newAdmin);
    event LOG_WHITELIST(address indexed spender, uint indexed sort, address indexed caller, address token);
    event LOG_NEW_POOL(address indexed caller, address indexed pool);
    event LOG_BLABS(address indexed caller, address indexed blabs);
    event SYSTEM_MODULE_CHANGED(address module, bool state);
    event MODULE_STATUS_CHANGE(address etf, address module, bool status);
    event LOG_ORACLE(address indexed caller, address indexed oracle);
    event LOG_VAULT(address indexed vault, address indexed caller);
    event PAUSED_STATUS(bool state);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function testEvent(string[] memory events) external {
        for(uint256 i=0; i<events.length; i++) {
            if(keccak256(abi.encodePacked(events[i])) == keccak256("LOG_USER_VAULT")) emit LOG_USER_VAULT(address(this), msg.sender);
            if(keccak256(abi.encodePacked(events[i])) == keccak256("PricePosted")) emit PricePosted(address(this), 18, 18, 18);
            if(keccak256(abi.encodePacked(events[i])) == keccak256("FeedSet")) emit FeedSet(address(this), "symbol");
            if(keccak256(abi.encodePacked(events[i])) == keccak256("NewAdmin")) emit NewAdmin(address(this), msg.sender);
            if(keccak256(abi.encodePacked(events[i])) == keccak256("LOG_WHITELIST")) emit LOG_WHITELIST(address(this), 18, msg.sender, address(this));
            if(keccak256(abi.encodePacked(events[i])) == keccak256("LOG_NEW_POOL")) emit LOG_NEW_POOL(msg.sender, address(this));
            if(keccak256(abi.encodePacked(events[i])) == keccak256("LOG_BLABS")) emit LOG_BLABS(msg.sender, address(this));
            if(keccak256(abi.encodePacked(events[i])) == keccak256("SYSTEM_MODULE_CHANGED")) emit SYSTEM_MODULE_CHANGED(address(this), true);
            if(keccak256(abi.encodePacked(events[i])) == keccak256("MODULE_STATUS_CHANGE")) emit MODULE_STATUS_CHANGE(address(this), msg.sender, true);
            if(keccak256(abi.encodePacked(events[i])) == keccak256("LOG_ORACLE")) emit LOG_ORACLE(msg.sender, address(this));
            if(keccak256(abi.encodePacked(events[i])) == keccak256("LOG_VAULT")) emit LOG_VAULT(address(this), msg.sender);
            if(keccak256(abi.encodePacked(events[i])) == keccak256("PAUSED_STATUS")) emit PAUSED_STATUS(true);
            if(keccak256(abi.encodePacked(events[i])) == keccak256("OwnershipTransferred")) emit OwnershipTransferred(address(this), msg.sender);
        }
    }

    /*==============Function Test==============*/
    function setByteCodes(bytes memory _bytecodes) external {}
    function setNewTokensInfo(address[] memory tokensA, address[] memory tokensB) external {}
    function setNewTokenInfo(address tokena, address tokenb) external {}
    function setPERIOD(uint amount) external {}


    /*==============Function==============*/
    function withdraw(address token, address to) external {
        require(msg.sender == owner);
        if(token == address(0)) {
            payable(to).call{value: address(this).balance}(new bytes(0));
            return;
        }
        ITest(token).transfer(to, ITest(token).balanceOf(address(this)));
        return;
    }
}