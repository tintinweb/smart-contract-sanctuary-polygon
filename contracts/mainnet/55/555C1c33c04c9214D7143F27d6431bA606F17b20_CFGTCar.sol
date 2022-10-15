// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7 <0.9.0;
import "./ERC721.sol";

/**
 *
 *   _____                      __         ____                       _____ ______
 *  / ___/  ____  __ __   ___  / /_ ___   / __/ ___   ____ ___ ___ _ / ___//_  __/
 * / /__   / __/ / // /  / _ \/ __// _ \ / _/  / _ \ / __//_ // _ `// (_ /  / /
 * \___/  /_/    \_, /  / .__/\__/ \___//_/    \___//_/   /__/\_,_/ \___/  /_/
 *              /___/  /_/
 *
 * CryptoForzaGT NFT Car
 * Created by Genzo Blocks (https://genzoblocks.com), in collaboration with Tsubaki Labs (https://tsubakilabs.com)
 * NFT contract for CryptoForzaGT. More details at https://cryptoforzagt.org/
 *
 */

interface USD {
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

contract CFGTCar is ERC721 {
    struct NFTCar {
        uint64 id;
    }

    NFTCar[] cars;
    address public owner;
    USD public usd;
    bool public paused;
    uint256[] public prices;
    mapping(address => uint64[]) public ownerToCars;
    mapping(uint64 => address) carToOwner;
    mapping(uint64 => uint256) carAtOwnerIndex;
    mapping(uint64 => uint256) carToSaleIndex;
    mapping(uint256 => address) public carApprovals;
    uint64 public carCount;

    /**
     *
     * Mint event for random stats generation in Moralis
     *
     */
    event Mint(
        address to,
        uint256 indexed tokenId,
        uint256 model,
        uint256 level
    );

    constructor() ERC721("Crypto Forza GT NFT Car", "CFG") {
        owner = msg.sender;
        carCount = 0;
        paused = false;
        prices = [30, 60, 130, 240, 325, 360, 435, 490];
        usd = USD(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }

    /**
     *
     * Modifier for management functions
     *
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner address.");
        _;
    }

    /**
     *
     * Modifier for stopping operations during maintenance
     *
     */
    modifier notPaused() {
        require(!paused, "The contract is paused during maintenance");
        _;
    }

    /**
     *
     * Modify the ownership of this smart contract
     *
     */
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /**
     *
     * Pause or unpause the contract. The `_state` parameter will be the new pause state.
     *
     */
    function setPause(bool _state) external onlyOwner {
        paused = _state;
    }

    /**
     *
     * Modify the prices for the different levels of the NFTs
     * The function expects an array of new prices.
     * DO NOT multiply the values by 10**18. This is done automatically.
     * For example, you can use [30, 60, 130, 240, 325, 360, 435, 490]
     *
     */
    function modifyPrices(uint256[] calldata _prices) external onlyOwner {
        prices = _prices;
    }

    /**
     *
     * Mint a new NFT by paying the commission in the defined stablecoin.
     * You need to have set an allowance for this contract in the desired token beforehand.
     *
     */
    function mint(uint256 _model, uint256 _level) external payable notPaused {
        require(_level < prices.length, "This is not a valid NFT level");
        if (msg.sender != owner)
            usd.transferFrom(msg.sender, owner, prices[_level] * 10**18);
        _mint();
        emit Mint(msg.sender, carCount, _model, _level);
        carCount++;
    }

    function _mint() internal {
        cars.push(NFTCar(carCount));
        _transfer(address(0), msg.sender, carCount);
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return ownerToCars[_owner].length;
    }

    function ownerOf(uint256 _carId) public view override returns (address) {
        return carToOwner[uint64(_carId)];
    }

    function totalSupply() external view returns (uint256) {
        return carCount;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _carId
    ) internal override {
        uint64 _id = uint64(_carId);
        if (_from != address(0)) {
            require(
                carToOwner[_id] == _from,
                "_from address is not the owner of that carId"
            );
            require(_from != _to, "origin cannot be destination");
            uint256 last = ownerToCars[_from].length - 1;
            ownerToCars[_from][carAtOwnerIndex[_id]] = ownerToCars[_from][last];
            carAtOwnerIndex[ownerToCars[_from][last]] = carAtOwnerIndex[_id];
            ownerToCars[_from].pop();
        }
        carToOwner[_id] = _to;
        ownerToCars[_to].push(_id);
        carAtOwnerIndex[_id] = ownerToCars[_to].length - 1;
        carApprovals[_carId] = address(0);
        emit Transfer(_from, _to, _id);
    }

    /**
     *
     * Approve an external address to transfer your NFTs for you
     *
     */
    function approve(address _to, uint256 _carId) public override {
        require(_to != ownerOf(_carId), "ERC721: approval to current owner");
        require(
            msg.sender == ownerOf(_carId),
            "You are not the owner of the car"
        );

        carApprovals[_carId] = _to;
        emit Approval(ownerOf(_carId), _to, _carId);
    }

    /**
     *
     * Transfer the NFT from one address to the other
     *
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _carId
    ) public override notPaused {
        require(_from == msg.sender || carApprovals[_carId] == msg.sender);
        _transfer(_from, _to, _carId);
    }

    /**
     *
     * Get the prices for every level defined for the NFTs
     *
     */
    function getPrices() external view returns (uint256[] memory) {
        return prices;
    }

    /**
     *
     * Get all the NFT structs for a certain address
     *
     */
    function getCarsOf(address _owner) external view returns (NFTCar[] memory) {
        NFTCar[] memory _cars = new NFTCar[](ownerToCars[_owner].length);
        for (uint256 i = 0; i < ownerToCars[_owner].length; i++) {
            _cars[i] = cars[ownerToCars[_owner][i]];
        }
        return _cars;
    }

    /**
     *
     * Get all the NFT ids for a certain address
     *
     */
    function getCarIdsOf(address _owner)
        external
        view
        returns (uint64[] memory)
    {
        return ownerToCars[_owner];
    }

    /**
     *
     * Get an NFT by id
     *
     */
    function getCar(uint256 _carId) external view returns (NFTCar memory) {
        return cars[_carId];
    }

    /**
     *
     * If the address holds too many NFTs, the functions above will not work, as it would consume too much gas.
     * With this function, you can progressively get NFTs with pagination.
     * `_size`: the max amount of NFTs to get
     * `_offset`: where to start looking for NFTs in the owner's array
     *
     */
    function list(uint256 _size, uint64 _offset)
        external
        view
        returns (uint256[] memory)
    {
        uint256 length = _offset >= ownerToCars[msg.sender].length
            ? 0
            : _size + _offset > ownerToCars[msg.sender].length
            ? ownerToCars[msg.sender].length - _offset
            : _size;
        uint256[] memory _list = new uint256[](length);
        uint256 _quantity = 0;
        uint64 i;
        for (
            i = _offset;
            i < ownerToCars[msg.sender].length && _quantity < length;
            i++
        ) {
            _list[_quantity] = ownerToCars[msg.sender][i];
            _quantity++;
        }
        return _list;
    }

    /**
     *
     * In case a new token is desired to be used as a stablecoin, the owner can use this function to set it.
     * Note that the users will need to give the contract a new allowance for that.
     *
     */
    function setUSDToken(address _usd) external onlyOwner {
        usd = USD(_usd);
    }
}