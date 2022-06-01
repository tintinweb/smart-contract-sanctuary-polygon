/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IDriss {
    function getIDriss(string memory hashPub) external view returns (string memory);
    function IDrissOwners(string memory _address) external view returns(address);
}

contract Test {   

    address public contractOwner = msg.sender; 
    mapping(string => string) public walletTags;
    mapping(address => string) public reverseIDriss;
    mapping(address => bool) private admins;
    address public IDrissAddr = 0x2EcCb53ca2d4ef91A79213FDDF3f8c2332c2a814;

    constructor() {
        walletTags["MM_ETH"] = "5d181abc9dcb7e79ce50e93db97addc1caf9f369257f61585889870555f8c321";
        walletTags["BINANCE_ETH"] = "4b118a4f0f3f149e641c6c43dd70283fcc07eacaa624efc762aa3843d85b2aba";
        walletTags["COINBASE_ETH"] = "92c7f97fb58ddbcb06c0d5a7cb720d74bc3c3aa52a0d706e477562cba68eeb73";
        walletTags["EXCHANGE_ETH"] = "ec72020f224c088671cfd623235b59c239964a95542713390a2b6ba07dd1151c";
        walletTags["PRIVATE_ETH"] = "005ba8fbc4c85a25534ac36354d779ef35e0ee31f4f8732b02b61c25ee406edb";
        walletTags["ERC20"] = "63d95e64e7caff988f97fdf32de5f16624f971149749c90fbc7bbe44244d3ced";
        walletTags["ESSENTIALS_ETH"] = "3ea9415b82f0ee7db933aab0be377ee1c1a405969d8b8c2454bcce7372a161c2";
        walletTags["RAINBOW_ETH"] = "992335db5f54ef94a5f23be8b925ed2529b044537c19b59643d39696936b6d6c";
        walletTags["ARGENT_ETH"] = "682614f9b037714bbf001db3a8d6e894fbdcf75cbbb9dea5a42edce33e880072";
        walletTags["TALLY_ETH"] = "f368de8673a59b860b71f54c7ba8ab17f0b9648ad014797e5f8d8fa9f7f1d11a";
        walletTags["TRUST_ETH"] = "df3d3f0233e396b2b27c3943269b10ecf2e7c1070a485e1b6b8f2201cb23cb52";
        walletTags["METAMASK_USDT"] = "74a3d8986c81769ed3bb99b773d66b60852f7ee3fa0d55a6a144523116c671c1";
        walletTags["BINANCE_USDT"] = "77c27c19cc85e24b1d4650800cc4b1bc607986dd3e78608435cececd31c35015";
        walletTags["COINBASE_USDT"] = "f2faabf9d133f31a13873ba8a15e676e063a730898ffadfcb0077f723260f563";
        walletTags["EXCHANGE_USDT"] = "683e7b694b374ce0d81ba525361fa0c27fff7237eb12ec41b6e225449d5702b9";
        walletTags["PRIVATE_USDT"] = "8c9a306a7dc200c52d32e3c1fcbf2f65e8037a68127b81807e8e58428004bc57";
        walletTags["ESSENTIALS_USDT"] = "74dcb573a5c63382484f597ae8034a6153c011e291c01eb3da40e9d83c436a9a";
        walletTags["METAMASK_USDC"] = "6f763fea691b1a723ef116e98c02fae07a4397e1a2b4b4c749d06845fa2ff5e4";
        walletTags["BINANCE_USDC"] = "7d2b0e0ee27a341da84ce56e95eb557988f9d4ff95fe452297fc765265bb27a2";
        walletTags["COINBASE_USDC"] = "6fe7c1a2fdd154e0b35283598724adee9a5d3b2e6523787d8b6de7cd441f15ca";
        walletTags["EXCHANGE_USDC"] = "8c4a231c47a4cfa7530ba4361b6926da4acd87f569167b8ba55b268bf99640d0";
        walletTags["PRIVATE_USDC"] = "54c9da06ab3d7c6c7f813f36491b22b7f312ae8f3b8d12866d35b5d325895e3e";
        walletTags["ESSENTIALS_USDC"] = "23a66df178daf25111083ee1610fb253baf3d12bd74c6c2aae96077558e3737a";
        walletTags["METAMASK_BNB"] = "3bee8eefc6afe6b4f7dbcc024eb3ad4ceaa5e458d34b7877319f2fe9f676e983";
        walletTags["ESSENTIALS_BNB"] = "639c9abb5605a14a557957fa72e146e9abf727be32e5149dca377b647317ebb9";
        walletTags["ESSENTIALS_ELA_SC"] = "c17c556467fe7c9fe5667dde7ca8cdbca8a24d0473b9e9c1c2c8166c1f355f6c";
        walletTags["ESSENTIAL_MATIC"] = "336fb6cdd7fec196c6e66966bd1c326072538a94e700b8bc1111d1574b8357ba";
        walletTags["TWITTER"] = "9306eda974cb89b82c0f38ab407f55b6d124159d1fa7779f2e088b2b786573c1";
    }


    function addAdmin(address adminAddress) external {
        require(msg.sender == contractOwner, "Only contractOwner can add admins.");
        admins[adminAddress] = true;
    }


    function deleteAdmin(address adminAddress) external {
        require(msg.sender == contractOwner, "Only contractOwner can delete admins.");
        admins[adminAddress] = false;
    }


    function addWalletTag(string memory _tag, string memory _tagHash) external {
        require(admins[msg.sender] == true, "Only admin can add wallet tag.");
        walletTags[_tag] = _tagHash;
    }


    function deleteWalletTag(string memory _tag) external {
        require(admins[msg.sender] == true, "Only admin can delete wallet tag.");
        delete walletTags[_tag];
    }


    function registerReverseIDriss(string memory _handle, string memory _walletTag) external {
        string memory _hashPub =  getSlice(toHex(sha256(abi.encodePacked(_handle, walletTags[_walletTag]))));
        require(checkIDrissOwnership(_hashPub), "You don't own this IDriss.");
        require(checkIDrissResolve(_hashPub), "This IDriss is not resolving.");
        reverseIDriss[msg.sender] = _handle;
    }


    function deleteReverseMapping() external {
        delete reverseIDriss[msg.sender];
    }

    function checkIDrissOwnership(string memory _hashPub) internal view returns (bool){
        address ownerIDrissAddr = IDriss(IDrissAddr).IDrissOwners(_hashPub);
        return ownerIDrissAddr==msg.sender;
    }

    function checkIDrissResolve(string memory _hashPub) internal view returns (bool){
        string memory IDrissAddrResolved = toLower(IDriss(IDrissAddr).getIDriss(_hashPub));
        return keccak256(abi.encodePacked(addressToString(msg.sender)))==keccak256(abi.encodePacked(IDrissAddrResolved));
    }

    // helper function to translate byte -> string
    function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256 (result) +
            (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 39);
    }

    // btes32 to string
    function toHex (bytes32 data) internal pure returns (string memory) {
        return string (abi.encodePacked ("0x", toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
    }

    // compare IDriss hash with inputs
    function hashCompare(string memory string1, string memory string2, string memory string3) internal pure returns (bool) {
        return keccak256(abi.encodePacked(string3)) == keccak256(abi.encodePacked(string1, string2));
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(address(_address))));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function getSlice(string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(64);
        for(uint i=0;i<=63;i++){
            a[i] = bytes(text)[i+2];
        }
        return string(a);    
    }

    function transferContractOwnership(address newOwner) public payable {
        require(msg.sender == contractOwner, "Only contractOwner can change ownership of contract.");
        require(newOwner != address(0), "Ownable: new contractOwner is the zero address.");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        contractOwner = newOwner;
    }
}