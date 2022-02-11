/**
 *
 *  Reward Tracks
 *
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.4;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    constructor () {
        __Ownable_init();
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

contract RewardTracks is OwnableUpgradeable{
    // counter for Track Ids
    //using CountersUpgradeable for CountersUpgradeable.Counter;
    //CountersUpgradeable.Counter private _trackIds;
    uint256 private _trackIds;
    address private _rewardsContractAddress;

    mapping(address => TrackMeta[]) genericContractTracks;
    mapping(address => mapping(uint256 => TrackMeta[])) specificCardTracks;
    mapping(address => mapping(uint256 => uint256)) NftTracksCount;
    mapping(address => uint256) ContractTracksCount;
    // mapping from trackId to Track metadata
    mapping(uint256 => TrackMeta) id2Meta;

    // Track Metadata
    struct TrackMeta {
        uint256 id;
        bool isNftSpecific; // true when track is Nft specific
        address contractAddress; // nft contract address
        uint256 tokenId;    // is zero when it's Not Nft specific
        string name;
        string image;
        string description;
        string source;
        uint256 rewardsRate;
        uint256 trackDuration;
        bool isAdvertisement;
    }

    function setRewardsContractAddress (address _rewardsContract) public onlyOwner {
      _rewardsContractAddress = _rewardsContract;
    }

    /**
     * @dev adds track to Token Owned Tracks
     * @param _tokenId uint256 tokenID
     * @param _name string track name
     * @param _image string track image URI
     * @param _description string track description
     * @param _source string track source
     */
    function _addTrackToSpecificCard(
        address _nftContract,
        uint256 _tokenId,
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _source,
        uint256 _rewards,
        uint256 _trackDuration,
        bool isAdvertisement
    ) public
      returns (uint256){
        //require(_msgSender() == _rewardsContractAddress,'caller is not authorized to add tracks');
        // increment Track id by one
        _trackIds = _trackIds + 1 ;
        // set new track id
        uint256 newTrackId = _trackIds;
        // Create a new struct of type "TrackMeta" 
        TrackMeta memory meta = TrackMeta(newTrackId , true, _nftContract, _tokenId,_name, _image, _description, _source, _rewards, _trackDuration, isAdvertisement);
        specificCardTracks[_nftContract][_tokenId].push(meta);
        NftTracksCount[_nftContract][_tokenId] = NftTracksCount[_nftContract][_tokenId] + 1;
        
        // add trackMeta to "id2Meta" mapping
        id2Meta[newTrackId] = meta;

        return newTrackId;
    }

    function _addTrackToContract(
        address _nftContract,
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _source,
        uint256 _rewards,
        uint256 _trackDuration,
        bool isAdvertisement
    ) public 
      returns(uint256) {
        //require(_msgSender() == _rewardsContractAddress,'caller is not authorized to add tracks');
        // increment Track id by one
        _trackIds = _trackIds + 1;
        // set new track id
        uint256 newTrackId = _trackIds;
        // Create a new struct of type "TrackMeta" 
        TrackMeta memory meta = TrackMeta(newTrackId , false, _nftContract, 0,_name, _image, _description, _source, _rewards, _trackDuration, isAdvertisement);
        genericContractTracks[_nftContract].push(meta);
        //specificCardTracks[_nftContract][_tokenId].push(meta);
        //AddressTokenTracksCount[_nftContract][_tokenId] = AddressTokenTracksCount[_nftContract][_tokenId] + 1;
        ContractTracksCount[_nftContract] = ContractTracksCount[_nftContract] + 1;
        // add Id2MetaContract 
        id2Meta[newTrackId] = meta;
        return newTrackId;
    }
    
    /** get tracks added specificily for Nft card */
    function getSpecificNftTracks(
      address _nftContract,
      uint256 _tokenId
    )public view returns(TrackMeta[] memory){
      uint nftTracksCount = NftTracksCount[_nftContract][_tokenId];
      TrackMeta[] memory nftTracksMeta = new TrackMeta[](nftTracksCount);
      //uint Counter = 0;
      
      nftTracksMeta = specificCardTracks[_nftContract][_tokenId];
      return nftTracksMeta;
    }

    /** get generic tracks added to contract */
    function getGenericContractTracks(
        address _nftContract
    ) public view returns(TrackMeta[] memory) {
        uint contractTrackCount = ContractTracksCount[_nftContract];
        TrackMeta[] memory nftTracksMeta = new TrackMeta[](contractTrackCount);
        //uint Counter = 0;
        
        nftTracksMeta = genericContractTracks[_nftContract];
        return nftTracksMeta;
    }

    /** get nft card tracks */
    function getGenericAndSpecificNftTracks(address _nftContractAddress, uint256 _tokenId) public view returns(TrackMeta[] memory){
      TrackMeta[] memory allTracks = new TrackMeta[](_trackIds);
      uint256 counter = 0;

      for (uint256 i = 1; i < _trackIds + 1; i++){        
        bool _isSameContractAddress = id2Meta[i].contractAddress == _nftContractAddress;
        bool _isSameTokenId = id2Meta[i].tokenId == _tokenId;

        bool _isGeneric = _isSameContractAddress && !id2Meta[i].isNftSpecific;
        bool _isSpecific = _isSameContractAddress && id2Meta[i].isNftSpecific && _isSameTokenId;

        if(_isGeneric || _isSpecific) {
          allTracks[counter] = id2Meta[i];
        }
      }
      return allTracks;
    }

    /** get advertisement tracks */
    function getAdTracks() public view returns(TrackMeta[] memory){
      TrackMeta[] memory allTracks = new TrackMeta[](_trackIds);
      uint256 counter = 0;

      for (uint256 i = 1; i < _trackIds + 1; i++){
        if(id2Meta[i].isAdvertisement) {
          allTracks[counter] = id2Meta[i];
        }
      }
      return allTracks;
    }

    /** get all tracks */
    function getAllTracks() public view returns(TrackMeta[] memory){
        TrackMeta[] memory allTracks = new TrackMeta[](_trackIds);
        uint256 counter = 0;

        for (uint256 i = 1; i < _trackIds + 1; i++) {
            allTracks[counter] = id2Meta[i];
            counter++;
        }
        return allTracks;
    }

    
    function _getTrackDuration(
      uint256 _trackId
    ) public
      view
     returns(uint256){
       // return trackId metadata
       return id2Meta[_trackId].trackDuration;
    }

    function _getTrackRewards(
      uint256 _trackId
    )public
      view
     returns(uint256){
       // return trackId metadata
       return id2Meta[_trackId].rewardsRate;
    }
}