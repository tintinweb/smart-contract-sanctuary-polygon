/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

pragma solidity 0.8.17;

contract VirtualBattery{
    
    event offerListed(  uint256 indexed id, 
                        uint256 indexed price, 
                        uint256 indexed KWH,
                        uint256 start, 
                        uint256 end,
                        uint256 expiry
    );

    event offerAccepted(uint256 indexed id, 
                        uint256 indexed price, 
                        uint256 indexed KWH,
                        uint256 start, 
                        uint256 end
    );

    event offerInvalidated(uint256 indexed id, 
                        uint256 indexed price, 
                        uint256 indexed KWH,
                        uint256 start, 
                        uint256 end
    );

    event offerDeleted( uint256 indexed id,
                        address indexed owner
    );

    uint256 id;
    address admin;
    uint256 public  currentRateKWH; //in cEUR
    uint256 FeePercentage = 7;
    uint256 Balance;

    mapping( address => bool) public m_registeredUsers;
    mapping( address => uint256) public m_wallet;
    mapping( uint256 => s_Package ) public m_package;
    mapping( address => uint256) public m_userOffers;
    mapping( address => uint256) public m_packageInUse;

    function checkAdmin() private view {
        require(msg.sender == admin, "unauthorized call");
    }

    function checkIfRegistered() private view {
        require(m_registeredUsers[msg.sender] == true, "unregistered address");
        require(msg.sender != admin, "admin cannot register");
    }

    modifier isAdmin(){
        checkAdmin();
        _;
    }

    modifier isRegistered() {
        checkIfRegistered();
        _;
    }

    function setPriceperKWH(uint256 _price) isAdmin external {
        currentRateKWH = _price;
    }

    function setFeePercentage(uint256 _fee) isAdmin external {
        FeePercentage = _fee;
    }

    struct s_Package{
        address owner;
        uint256 price;
        uint128 KWH;
        bool    onSale;
        uint256 end;
        uint256 start;
        uint256 expiry;
    }
    
    constructor(){
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

    function makeOffer( uint256 _price, 
                        uint128 _KWH, 
                        uint256 _end, 
                        uint256 _start, 
                        uint256 _expiry) external isRegistered {

        if (_start >= _end || _expiry >= _start){
            revert("expiry < start < end ");
        }
        if (_expiry < block.timestamp + 3600 ){
            revert("Expiry should be atleast 1 hour from now ");
        }
        
        ++id;
        m_package[id] = s_Package({ owner: msg.sender,
                                    price: _price,
                                    KWH: _KWH,
                                    onSale: true,
                                    start: _start,
                                    end: _end,
                                    expiry: _expiry });

        emit offerListed(id, _price, _KWH, _start,  _end, _expiry);
        m_userOffers[msg.sender] = id;
    } 

    function calculatePercentage(uint256 _val) private view returns(uint256){
        return (_val * FeePercentage)/100; 
    }

    function acceptOffer(uint256 _pkgId) external payable isRegistered {
        if( m_packageInUse[msg.sender] > 0 && m_package[m_packageInUse[msg.sender]].start < block.timestamp  ){
            m_packageInUse[msg.sender] = 0;
        }
        
        //require( m_packageInUse[msg.sender] == 0, "You are already using a package.");
        s_Package memory pkg = m_package[_pkgId]; 
        require(pkg.onSale == true, "not on sale");
        address prevOwner = pkg.owner;
        require(prevOwner != msg.sender, "owner cannot buy their own package");

        if (pkg.expiry <= block.timestamp) {
            pkg.onSale = false;
            emit offerInvalidated(_pkgId, pkg.price, pkg.KWH, pkg.start,  pkg.end);
            m_userOffers[msg.sender] = id;
        }
        else{
            require(msg.value == pkg.price, "incorrect funds");
            pkg.onSale = false;
            pkg.owner = msg.sender;
            uint256 fee = calculatePercentage(pkg.price);
            uint256 newPrice = pkg.price - fee;
            m_wallet[admin] += fee;
            m_wallet[prevOwner] += newPrice;
            Balance += msg.value;
            m_packageInUse[msg.sender] =_pkgId;
            emit offerAccepted(_pkgId, pkg.price, pkg.KWH, pkg.start,  pkg.end);
        }
        m_userOffers[prevOwner] = 0;
        m_package[_pkgId] = pkg; 
    }

    function withdrawFunds() external payable  {
        (bool s, ) = payable(msg.sender).call{value:m_wallet[msg.sender]}("");
        require(s, "call failed");
        m_wallet[msg.sender] = 0;
    }

    function withdrawOffer(uint256 _pkgId) external isRegistered {
        s_Package memory pkg = m_package[_pkgId]; 
        require(pkg.owner == msg.sender, "only package owner can withdraw" );
        require(pkg.onSale == true, "inactive Offer");
        delete m_package[_pkgId];
        m_userOffers[msg.sender] = 0;
        emit offerDeleted(_pkgId, msg.sender);
    }
}