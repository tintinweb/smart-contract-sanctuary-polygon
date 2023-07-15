/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract VirtualBattery {
    
    event offerListed(uint256 indexed id, uint256 indexed price, uint256 indexed KWH, uint256 start, uint256 end);
    event offerAccepted(uint256 indexed id, uint256 indexed price, uint256 indexed KWH, uint256 start, uint256 end);
    event offerInvalidated(uint256 indexed id, uint256 indexed price, uint256 indexed KWH, uint256 start, uint256 end);
    event offerDeleted(uint256 indexed id, address indexed owner);

    uint256 id;
    address admin;
    uint256 public currentRateKWH;
    uint256 FeePercentage = 5;
    uint256 Balance;

    mapping(address => bool) public m_registeredUsers;
    mapping(address => uint256) public m_wallet;
    mapping(uint256 => s_Package) public m_package;
    mapping(address => uint256) public m_userOffers;
    mapping(address => uint256) public m_packageInUse;

    function checkAdmin() private view {
        require(msg.sender == admin, "unauthorized call");
    }

    function checkIfRegistered() private view {
        require(m_registeredUsers[msg.sender] == true, "unregistered address");
        require(msg.sender != admin, "admin cannot register");
    }

    modifier isAdmin() {
        checkAdmin();
        _;
    }

    modifier isRegistered() {
        checkIfRegistered();
        _;
    }
    
    function setPricePerKWH(uint256 _priceInWei) external isAdmin {
        currentRateKWH = _priceInWei;
    }


    function setFeePercentage(uint256 _fee) external isAdmin {
        FeePercentage = _fee;
    }

    struct s_Package {
        address owner;
        uint256 price;
        uint128 KWH;
        bool    onSale;
        uint256 end;
        uint256 start;
    }

    constructor() {
        admin = msg.sender;
    }

    function getLatestPackage() external view returns(uint256){
        return id;
    }

    function registerUser(address _user) external isAdmin {
        m_registeredUsers[_user] = true;
    }

    function banUser(address _user) external isAdmin {
        m_registeredUsers[_user] = false;
    }

    function makeOffer(uint256 _price, uint128 _KWH, uint256 _end, uint256 _start) external isRegistered {
        require(_start < _end, "start must be less than end");
        require(_price <= currentRateKWH, "offer price cannot exceed current rate per KWH");

        ++id;
        m_package[id] = s_Package({ owner: msg.sender, price: _price, KWH: _KWH, onSale: true, start: _start, end: _end});
        emit offerListed(id, _price, _KWH, _start, _end);
        m_userOffers[msg.sender] = id;
    }

    function calculatePercentage(uint256 _val) private view returns(uint256){
        return (_val * FeePercentage) / 100;
    }

    function acceptOffer(uint256 _pkgId) external payable isRegistered {
        if (m_packageInUse[msg.sender] > 0 && m_package[m_packageInUse[msg.sender]].start < block.timestamp) {
            m_packageInUse[msg.sender] = 0;
        }
 
        s_Package memory pkg = m_package[_pkgId];
        require(pkg.onSale == true, "not on sale");
        address prevOwner = pkg.owner;
        require(prevOwner != msg.sender, "owner cannot buy their own package");

        require(msg.value == pkg.price, "incorrect funds");

        pkg.onSale = false;
        pkg.owner = msg.sender;
        uint256 fee = calculatePercentage(pkg.price);
        uint256 newPrice = pkg.price - fee;
        m_wallet[admin] += fee;
        m_wallet[prevOwner] += newPrice;
        Balance += msg.value;
        m_packageInUse[msg.sender] = _pkgId;
        emit offerAccepted(_pkgId, pkg.price, pkg.KWH, pkg.start, pkg.end);

        m_userOffers[prevOwner] = 0;
        m_package[_pkgId] = pkg;
    }

    function withdrawFunds() external payable {
        (bool s, ) = payable(msg.sender).call{value:m_wallet[msg.sender]}("");
        require(s, "call failed");
        m_wallet[msg.sender] = 0;
    }

    function withdrawOffer(uint256 _pkgId) external isRegistered {
        s_Package memory pkg = m_package[_pkgId];
        require(pkg.owner == msg.sender, "only package owner can withdraw");
        require(pkg.onSale == true, "inactive Offer");
        delete m_package[_pkgId];
        m_userOffers[msg.sender] = 0;
        emit offerDeleted(_pkgId, msg.sender);
    }

    function getOffer(uint256 _pkgId) external view returns (address owner, uint256 price, uint128 KWH, bool onSale, uint256 start, uint256 end) {
        s_Package memory pkg = m_package[_pkgId];
        return (pkg.owner, pkg.price, pkg.KWH, pkg.onSale, pkg.start, pkg.end);
    }
}


/*FLOW:


Admin has to register users first. Admin can also ban them and update current market rate per KWH and the fee percentage.
Users can then make offers to sell energy packages or buy valid packages.
    UNIX EPOCH time is used to add start, end times. 
    These offers can be withdrawn if they have not been sold using the withdrawOffer function.
Users can buy a package using its id.
    the fee will be charged by the admin and the remaining amount will go to the package owner(offer maker).
    this amount can be collected using the withdraw funds function.
*/