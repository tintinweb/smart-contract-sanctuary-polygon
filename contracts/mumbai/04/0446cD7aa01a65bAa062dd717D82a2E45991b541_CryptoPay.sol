// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//import "@thirdweb-dev/contracts/extension/PlatformFee.sol";

//contract CryptoPay is PlatformFee {
contract CryptoPay {
    address payable private owner;
    uint256 private commission;
    mapping(address => string) private apiKeys;

    event CommissionChanged(uint256 newCommission);
    event ApiKeyGenerated(address indexed account, string apiKey);
    event PaymentProcessed(address indexed buyer, string apiKey, uint256 amount);

    constructor() {
        owner = payable(0x66353cc9331D1BA1aFCfC6F31cC2116FfE102cE2);
        commission = 0; // 0.5% expressed as an integer
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    /**
     *  This function returns who is authorized to set platform fee info for your contract.
     *
     *  As an EXAMPLE, we'll only allow the contract deployer to set the platform fee info.
     *
     *  You MUST complete the body of this function to use the `PlatformFee` extension.
     */
//    function _canSetPlatformFeeInfo() internal view virtual override returns (bool) {
//        return msg.sender == owner;
//    }

    function setCommission(uint256 newCommission) public onlyOwner {
        commission = newCommission;
        emit CommissionChanged(newCommission);
    }

    function generateApiKey() public {
        require(bytes(apiKeys[msg.sender]).length == 0, "API key already exists");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty));
        string memory apiKey = bytes32ToString(hash);

        apiKeys[msg.sender] = apiKey;

        emit ApiKeyGenerated(msg.sender, apiKey);
    }

    function processPayment(string memory apiKey, string memory metadata, uint256 amount) public payable {
        require(msg.value == amount, "Amount does not match value sent");

        string memory storedApiKey = apiKeys[msg.sender];
        require(bytes(storedApiKey).length > 0, "API key not found");

        require(keccak256(abi.encodePacked(apiKey)) == keccak256(abi.encodePacked(storedApiKey)), "Invalid API key");

        uint256 commissionAmount = (amount * commission) / 1000;
        uint256 netAmount = amount - commissionAmount;

        owner.transfer(commissionAmount);
        payable(msg.sender).transfer(netAmount);

        emit PaymentProcessed(msg.sender, apiKey, amount);
    }

    function getApiKey(address account) public view returns (string memory) {
        return apiKeys[account];
    }

    function getCommission() public view returns (uint256) {
        return commission;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);

        for (i = 0; i < 32; i++) {
            uint8 value = uint8(_bytes32[i]);
            bytesArray[i * 2] = bytes1(uint8ToHex(value / 16));
            bytesArray[i * 2 + 1] = bytes1(uint8ToHex(value % 16));
        }
        return string(bytesArray);
    }

    function uint8ToHex(uint8 _value) internal pure returns (bytes1) {
        if (_value < 10) {
            return bytes1(uint8(_value + 48));
        } else {
            return bytes1(uint8(_value + 87));
        }
    }
}