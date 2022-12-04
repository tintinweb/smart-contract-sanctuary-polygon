/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Veriface.sol


pragma solidity >=0.7.0 <0.9.0;



error addressBlocked(address sender, string message);
error deniedService(address sender, string message);

contract Veriface is Ownable{
    mapping(address=>BlackListData) private _blaclistedAddresses;
    mapping(address=>bool) private _whiteListedsAddresses;
    mapping(address=>string) private _blaclistedAddressesDetails;
    mapping(address=>bool) public admins;

    constructor(){
        admins[msg.sender] = true;
    }


    struct BlackListData{
        uint256 time;
        bool blackListed;
        string uri;
        address by;
    }

    event SuspiciousUser(address user, address indexed callerContract, uint256 indexed time);
    
    event WhiteListedAddresses(address[] addresses, uint256 time);
    event BlackListedAddresses(address[] addresses, uint256 time);

    event RemovedWhiteListedAddresses(address[] addresses, uint256 time);
    event RemovedBlackListedAddresses(address[] addresses, uint256 time);

    event NewAdmin(address indexed newAdmin, uint256 indexed timestamp);
    event RemovedAdmin(string reason, address indexed newAdmin, uint256 indexed timestamp);

    modifier onlyAdmin(){
        require(admins[msg.sender] || msg.sender == owner(), "admins only");
        _;
    }
    
    function retrieveAddressStatus(address userAddress) public view returns(bool isBlaclisted) {
       return _blaclistedAddresses[userAddress].blackListed;
    }

    function retrieveWhiteListedAddressStatus(address userAddress) public view returns(bool isWhiteListed) {
       return _whiteListedsAddresses[userAddress];
    }

    


    //only owner

    //blacklist functions
    //remove it from blacklisted if blacklisted
    function blackList(address userAddress, string memory blackListUri) external onlyAdmin{
        _blaclistedAddresses[userAddress] =  BlackListData({
            time: block.timestamp,
            blackListed: true,
            uri: blackListUri,
            by: msg.sender
        });
        if( _whiteListedsAddresses[userAddress] = true){
             _whiteListedsAddresses[userAddress] = false;
        }
        address[] memory user = new address[](1);
        user[0] = userAddress;
        emit BlackListedAddresses(user, block.timestamp);
    }

    function batchBlackList(address[] memory userAddresses, string[] memory uris) external onlyAdmin{
        require(userAddresses.length == uris.length, "details not not match");
        for(uint i = 0; i < userAddresses.length; i++){
            if( _whiteListedsAddresses[userAddresses[i]] = true){
                 _whiteListedsAddresses[userAddresses[i]] = false;
            }
            if(_blaclistedAddresses[userAddresses[i]].blackListed == false){
                _blaclistedAddresses[userAddresses[i]] =  BlackListData({
                    time: block.timestamp,
                    blackListed: true,
                    uri: uris[i],
                    by: msg.sender
                });
            }
        }
        emit BlackListedAddresses(userAddresses, block.timestamp);
    }

    function removeBlackList(address userAddress) external onlyAdmin{
       delete _blaclistedAddresses[userAddress];
        address[] memory user = new address[](1);
        user[0] = userAddress;
        emit RemovedBlackListedAddresses(user, block.timestamp);
    }

    function removeBatchBlackList(address[] memory userAddresses) external onlyAdmin{
        for(uint256 i = 0; i < userAddresses.length; i++){
            if(_blaclistedAddresses[userAddresses[i]].blackListed == true){
                delete _blaclistedAddresses[userAddresses[i]];
            }
        }
        emit RemovedBlackListedAddresses(userAddresses, block.timestamp);
    }

    //require Digital identity verification

    //whitelist functions
    //remove it from blacklisted if blacklisted
    function whitelist(address userAddress) external onlyAdmin {
        _whiteListedsAddresses[userAddress] = true;
         address[] memory user = new address[](1);
        user[0] = userAddress;
        emit WhiteListedAddresses(user, block.timestamp);
    }

    function batchwhiteList(address[] memory userAddresses) external onlyAdmin {
        for(uint256 i = 0; i < userAddresses.length; i++){
            if(_whiteListedsAddresses[userAddresses[i]] == false){
                _whiteListedsAddresses[userAddresses[i]] = true;
            }
        }
        emit WhiteListedAddresses(userAddresses, block.timestamp);
    }

    function removeWhitelist(address userAddress) external onlyAdmin{
        _whiteListedsAddresses[userAddress] = false;
         address[] memory user = new address[](1);
        user[0] = userAddress;
        emit RemovedWhiteListedAddresses(user, block.timestamp);
       
    }

    function batchremoveWhiteList(address[] memory userAddresses) external onlyAdmin {
        for(uint256 i = 0; i < userAddresses.length; i++){
            if(_whiteListedsAddresses[userAddresses[i]] == true){
                _whiteListedsAddresses[userAddresses[i]] = false;
            }
        }
        emit RemovedWhiteListedAddresses(userAddresses, block.timestamp);
    }


    //helper functions
    function checkAddress(address sender, address callerContract, uint256 level) public {
        bool isBlackListed = _blaclistedAddresses[sender].blackListed;
        if(isBlackListed == true){
            if(level == 0){
                revert addressBlocked({
                    sender: sender,
                    message: "your account was denied interaction"
                });
            }else if(level == 1){
                emit SuspiciousUser(sender, callerContract, block.timestamp);
            }
        }
    }
    
    /*
     - requireAddressWhiteListed: that address is whitelised and deny or allow service
     - @sender: sender of the transaction(msg.sender)
     - @refuseService: bool input decide to refuse sender the service
    */
    function requireAddressWhiteListed(address sender, bool refuseService) external view {
        bool isWhiteListed = _whiteListedsAddresses[sender];
        if(isWhiteListed == false){
            if(refuseService == true){
                revert deniedService({
                    sender: sender,
                    message: "service only available for whitelisted addresses"
                });
            }
        }
    }

    //
    function addAdmin(address newAdmin) external onlyOwner{
        admins[newAdmin] = true;
        emit NewAdmin(newAdmin, block.timestamp);
    }

    function removeAdmin(address admin, string memory reason) external onlyOwner{
        delete admins[admin];
        emit RemovedAdmin(reason, admin, block.timestamp);
    }

    function isAdmin(address admin) public view returns(bool isAdminAddress){
        return admins[admin];
    }

}