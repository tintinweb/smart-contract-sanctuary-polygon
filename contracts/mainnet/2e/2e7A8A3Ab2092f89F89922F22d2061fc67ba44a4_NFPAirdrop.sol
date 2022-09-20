/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/NFPAirdrop.sol


pragma solidity ^0.8.0;



interface NFPixels{
    function isMinted(uint256 tokenId) external view returns(bool minted);
}

contract NFPAirdrop is Ownable{

    event airdropSent(address receiver, uint256 tokenId);
    event airdropReceived(address receiver, uint256 tokenId);
    event airdropCanceled(uint256 tokenId);

    // NFP 合约地址
    NFPixels _nfpContract;
    // tokenId => 目标地址
    mapping(uint256 => address) _airdropReceiver;
    // 空投发送时间
    mapping(uint256 => uint256) _airdropTime;
    // 所有空投
    uint256[] _airdropList;
    mapping(uint256 => uint256) _tokenIdToIndex;
    // address => 空投数量
    mapping(address => uint256) _airdropBalance;
    // address => (index => index in _airdropList)
    mapping(address => mapping(uint256 => uint256)) _airdropIndex;

    constructor() {
    }

    //////////////////////////// Private methods ////////////////////////////
    // 发送空投
    function _airdop(address adds, uint256 tokenId) internal{
        require((tokenId >= 1 && tokenId <= 1048576), "invalid tokenId");
        // 必须未被空投
        require(_airdropReceiver[tokenId] == address(0), "already airdropped");
        // 必须未mint
        require(address(_nfpContract) != address(0), "NFP contract not available");
        bool minted = _nfpContract.isMinted(tokenId);
        require(!minted, "check failed or already minted");
        // 空投
        _airdropReceiver[tokenId] = adds;
        _airdropTime[tokenId] = block.timestamp;
        _airdropList.push(tokenId);
        _tokenIdToIndex[tokenId] = _airdropList.length - 1;
        _airdropBalance[adds]++;
        _airdropIndex[adds][_airdropBalance[adds]-1] = _airdropList.length - 1;
        // 事件
        emit airdropSent(adds, tokenId);
    }

    // 清除空投
    function _removeAirdrop(uint256 tokenId) internal{
        require(_airdropReceiver[tokenId] != address(0), "not airdropping");
        address receiver = _airdropReceiver[tokenId];
        delete _airdropReceiver[tokenId];
        delete _airdropTime[tokenId];
        delete _airdropList[_tokenIdToIndex[tokenId]];
        delete _tokenIdToIndex[tokenId];
        _airdropBalance[receiver]--;
        delete _airdropIndex[receiver][_airdropBalance[receiver]];
        // 事件
        emit airdropCanceled(tokenId);
    }

    //////////////////////////// NFP Only ////////////////////////////
    // 空投已被接收的通知，清除掉空投 只有NFP合约可以调用
    function _receiveAirdrop(uint256 tokenId) external{
        require(msg.sender == address(_nfpContract), "NFP contract only");
        // 清除空投数据
        _removeAirdrop(tokenId);
        // 事件
        emit airdropReceived(msg.sender, tokenId);
    }

    //////////////////////////// Owner Only ////////////////////////////
    function setNFPContractAddress(address nfpAddress) onlyOwner external{
        _nfpContract = NFPixels(nfpAddress);
    }
    // 发送空投
    function airdop(address adds, uint256 tokenId) onlyOwner external{
        _airdop(adds, tokenId);
    }
    // 批量空投
    function batchAirdrop(address[] memory addressList, uint256[] memory tokenIdList) onlyOwner external{
        require(addressList.length == tokenIdList.length);
        uint len = addressList.length;
        for (uint i=0; i<len; i++) {
            require(addressList[i] != address(0), "empty address");
            _airdop(addressList[i], tokenIdList[i]);
        }
    }
    // 批量向一个地址空投
    function batchAirdropToAddress(address addr, uint256[] memory tokenIdList) onlyOwner external{
        require(addr != address(0), "empty address");
        require(tokenIdList.length > 0);
        uint len = tokenIdList.length;
        for (uint i=0; i<len; i++) {
            _airdop(addr, tokenIdList[i]);
        }
    }
    // 清除无人认领的空投
    function removeAirdrop(uint256 tokenId) onlyOwner external{
        // 清除空投数据
        _removeAirdrop(tokenId);
    }
    // 批量清楚无人认领的空投
    function removeAirdropList(uint256[] memory tokenIdList) onlyOwner external{
        uint len = tokenIdList.length;
        for (uint i = 0; i < len; i++){
            _removeAirdrop(tokenIdList[i]);
        }
    }
    
    //////////////////////////// 公开接口 ////////////////////////////
    
    // 钱包的空投数量
    function balanceOf(address targetAdds) external view returns(uint256 balance){
        return _airdropBalance[targetAdds];
    }

    // 钱包所持有的空投
    function airdropByIndexOfOwner(address adds, uint256 index) public view returns(uint256 tokenId){
        return _airdropList[_airdropIndex[adds][index]];
    }

    // 空投信息
    function airdropInfo(uint256 tokenId) external view returns(address receiver, uint256 airdropTime){
        return (_airdropReceiver[tokenId], _airdropTime[tokenId]);
    }

    // NFP是否被空投了
    function isAirdropped(uint256 tokenId) external view returns(bool){
        return (_airdropReceiver[tokenId] != address(0));
    }

    // 空投目标地址
    function airdropReceiver(uint256 tokenId) external view returns(address){
        return _airdropReceiver[tokenId];
    }

    // 查看合约地址
    function getNFPContractAddress() external view returns(address addrs){
        return address(_nfpContract);
    }
    
    // 钱包所持有的所有空投列表
    function airdropListOfAddress(address adds) external view returns(uint256[] memory tokenIdList){
        require(adds != address(0), "invalid address");
        uint256 balance = _airdropBalance[adds];
        uint256[] memory list = new uint256[](balance);
        uint256 i = 0;
        while (i < balance){
            list[i] = airdropByIndexOfOwner(adds, i);
            i++;
        }
        return list;
    }

    // 所有空投中的nfp
    function airdropList() external view returns(uint256[] memory tokenIdList){
        return _airdropList;
    }
}