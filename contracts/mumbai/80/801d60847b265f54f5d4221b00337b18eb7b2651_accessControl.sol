/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: QR/AccessControl.sol


pragma solidity ^0.8.0;




contract accessControl is Ownable, Pausable{
    using Counters for Counters.Counter;
    Counters.Counter public _fileIdCounter;
    enum accessType {VIEWER,EDITOR,ADMIN,MANAGER}
    struct User{
        string name;
        accessType typeAcess;
        uint[] directories;
        bool canAccessAll;
    } 
    // mapping the user by wallet
    mapping(address=>User) usersList;
    // user sessions registered the last 7 times
    mapping(address=>uint[7]) private UserSessions;
    // user current session index
    mapping(address=>uint) private userCurrentSessionIndex;
    // files Id created by the owner
    uint256[] private _filesId;    
    // users can access all files
    address[] private admins;
    // user => session expires in
    mapping(address=>uint) internal userAccess;
    ////////////////////// EVENTS //////////////////////
    event fileCreated(uint _idFile);
    event userCreated(address wallet,accessType access , uint [] directories, bool canAccessAll);   
    event accessGranted(address _user, uint[] _idFiles);
    event accessRevoked(address _user, uint[] _idFiles);
    event userTemporaryAccess(address _user, uint _expiresIn);
    event sessionCreated(address _user, uint _session);
    event adminAccess(address _user);
    event adminAccessRevoked(address _user);
    event AllAccessRevoked(address _user);
    event revokeSession(address wallet);

    constructor(){
         usersList[_msgSender()] = User("Admin",accessType.ADMIN,(new uint[](0)),true);
         setUserAdminAccess(_msgSender());
         _fileIdCounter.increment();
    }

    function existsFile(uint idFile) public view returns(bool _exists){
        for(uint i = 0; i < _filesId.length; i++){
            if(idFile == _filesId[i])
                return true;
        }
        return false;
    }

    function userHasAccess(address wallet,uint idFile) private view returns(bool _exists){
        for(uint i = 0; i < usersList[wallet].directories.length; i++){
            if(idFile == usersList[wallet].directories[i])
                return true;
        }
        return false;
    }

    function createFile() public onlyOwner{
        require(_fileIdCounter.current() <= 50,"Limit of 50 files per contract");
        _filesId.push(_fileIdCounter.current());
        for(uint i = 0; i < admins.length; i++){
            usersList[admins[i]].directories.push(_fileIdCounter.current());
        }
        emit fileCreated(_fileIdCounter.current());
        _fileIdCounter.increment();
    }

    function createUser(address wallet, uint typeUser, uint[] memory files, string memory userName ,bool canAccessAll)public onlyOwner{
        require(bytes(usersList[wallet].name).length < 1, "user already exists");
        require(bytes(userName).length > 0, "username can't be empty");
        require(typeUser < 4 && typeUser != 2, "invalid user type");
        require(files.length > 0, "No files id provided");
        for(uint i = 0; i < files.length; i++){
            require(existsFile(files[i]),"a file doesn't exists");
        }
        usersList[wallet] = User(userName,accessType(typeUser),files,canAccessAll);
        if(canAccessAll)
            setUserAdminAccess(wallet);   
        emit userCreated(wallet,accessType(typeUser),files,canAccessAll);     
    }
    
    function grantFileAccess(address wallet, uint[] calldata filesId) public onlyOwner{
        require(filesId.length > 0, "files not provided");
        require(wallet != address(0), "can't give null address permissions");
        for(uint i = 0; i<filesId.length; i++){
            require(existsFile(filesId[i]),"File doesn't exists");
            require(!userHasAccess(wallet,filesId[i]),"User already has access to a selected file");
            usersList[wallet].directories.push(filesId[i]);
        }
        emit accessGranted(wallet,filesId);
    }

    function revokeFileAccess(address user, uint[] calldata filesId) public onlyOwner{
        require(filesId.length > 0, "files not provided");
        require(user != address(0), "can't revoke null address permissions");
        uint len = usersList[user].directories.length;
        require(len > 0, "User doesn't have access to files");
        for(uint i = 0; i < filesId.length; i++){
            for(uint j = 0; j < usersList[user].directories.length; j++){
                if(usersList[user].directories[j] == filesId[i]){
                    delete usersList[user].directories[j];
                    len--;
                }
        }
        }
        uint[] memory temp = new uint[](len);
        uint index = 0;
        for(uint i = 0; i < usersList[user].directories.length;i++){
            if(usersList[user].directories[i] != 0){
                temp[index] = usersList[user].directories[i];
                index++;
            }
        }
        usersList[user].directories = temp;
        emit accessRevoked(user, filesId);
    }

    function getuserFilesAcess(address user) public view returns(uint[] memory filesCanAccess){
        return usersList[user].directories;
    }

    modifier hasAccess(){
        require(userAccess[_msgSender()] > block.timestamp, "user doesn't have any access");
        _;
    }

    function setUserAccess(address user, uint expiresIn)public onlyOwner{
        require(user != address(0), "null address provided");
        require(expiresIn > 0, "time must be greater than 0");
        uint _expiresIn =  block.timestamp+(1 days * expiresIn);
        userAccess[user] = _expiresIn;
        emit userTemporaryAccess(user,_expiresIn);
    }

    function userSession() public hasAccess{
        uint sessionTime = block.timestamp;
        UserSessions[_msgSender()][userCurrentSessionIndex[_msgSender()]] = sessionTime;
        if(userCurrentSessionIndex[_msgSender()] == 6)
            userCurrentSessionIndex[_msgSender()] = 0;
        else
            userCurrentSessionIndex[_msgSender()] += 1;
        emit sessionCreated(_msgSender(),sessionTime);
    }

    function getUserSessions(address wallet) public view returns(uint[7] memory sessions){
        return UserSessions[wallet];
    }

    function getUserCurrentSession(address wallet) public view returns(uint _expiresIn){
        return userAccess[wallet];
    }

    function revokeSessionUser(address wallet) public onlyOwner{
        require(userAccess[wallet] > 0 , "user doesn't have a session to revoke");
        delete userAccess[wallet];
        emit revokeSession(wallet);
    }

    function setUserAdminAccess(address wallet) public onlyOwner{
        require(!existsAdmin(wallet), "wallet already exists in admin list");
        admins.push(wallet);
        usersList[wallet].canAccessAll = true;
        setAdminAccess(wallet);
        emit adminAccess(wallet);
    }

    function existsAdmin(address wallet) internal view returns (bool){
        for(uint i = 0; i < admins.length; i++){
            if(admins[i] == wallet){
                return true;
            }
        }
        return false;
    }

    function setAdminAccess(address wallet) internal onlyOwner{
        usersList[wallet].directories = _filesId;
    }

    function revokeAllAccess(address wallet) public onlyOwner{
        delete usersList[wallet].directories;
        if(existsAdmin(wallet)){
            removeAdmin(wallet);
        }
        emit AllAccessRevoked(wallet);
    }

    function getAdminIndex(address wallet) internal view returns(uint value){
        for(uint i = 0; i < admins.length; i++){
            if(admins[i] == wallet)
                return i;
        }
        return (2 ** 256) - 1;
    }

    function removeAdmin(address wallet) public onlyOwner{
        uint index = getAdminIndex(wallet);
        require(index < ((2**256) - 1),"Error searching admin wallet!");
        admins[index] = admins[admins.length - 1];
        usersList[wallet].canAccessAll = false;
        admins.pop();  
        emit adminAccessRevoked(wallet);
    }

    function getAdmins() public view returns(address [] memory AdminAccessList){
        return admins;
    }

    function getUserData(address wallet) public view returns(User memory){
        return usersList[wallet];
    }

}