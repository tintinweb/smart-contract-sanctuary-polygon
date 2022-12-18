pragma solidity ^0.5.16;
import "./Proxy.sol";

contract IdentityManager {
    
    event IdentityCreated(address proxy);
    event IdentityRegistered(address proxy);
    event IdentityUnregistered(address proxy);
    event Upgraded(address oldIdentityManager, address newIdentityManager);
    event AccountRecovered(address proxy, address newUser);
    event CapSet(address identity, address device, string cap, uint start_date, uint end_date);

    struct Timerange {
        // Start date (0 means "doesn't have this cap")
        uint start;
        // End date (0 means "forever")
        uint end;
    }

    mapping (address => bool) public registered_identities;
    // Proxy => client => capability => bool
    mapping (address => mapping (address => mapping (string => Timerange))) capabilities;
    string private constant CAP_FORWARD = "fw";
    string private constant CAP_AUTH = "auth";
    string private constant CAP_DEVICE_MANAGER = "devicemanager";
    string private constant CAP_ADMIN = "admin";
    
    constructor() public {}
    
    function createIdentity(bytes16 keyMnemonic, bytes16 keyProfile, string memory urlProfile, string memory username, string memory salt) public returns (address){
        Proxy proxy = new Proxy(address(this));
        registered_identities[address(proxy)] = true;
        setFirstDevice(proxy, msg.sender, now, 0);
        emit IdentityCreated(address(proxy));
        return address(proxy);
    }
    
    function setFirstCap(Proxy identity, address device, string memory cap, uint start_date, uint end_date) private {
        capabilities[address(identity)][device][cap] = Timerange(start_date, end_date);
        emit CapSet(address(identity), device, cap, start_date, end_date);
    }
    
    function setFirstDevice(Proxy identity, address device, uint start_date, uint end_date) private {
        setFirstCap(identity, device, CAP_FORWARD, start_date, end_date);
        setFirstCap(identity, device, CAP_AUTH, start_date, end_date);
        setFirstCap(identity, device, CAP_DEVICE_MANAGER, start_date, end_date);
        setFirstCap(identity, device, CAP_ADMIN, start_date, end_date);
    }

    function setCap(Proxy identity, address device, string memory cap, uint start_date, uint end_date) public checkCap(identity, CAP_DEVICE_MANAGER) {
        capabilities[address(identity)][device][cap] = Timerange(start_date, end_date);
        emit CapSet(address(identity), device, cap, start_date, end_date);
    }

    function hasCap(Proxy identity, address device, string memory cap) public view returns (bool) {
        Timerange memory allowed_period = capabilities[address(identity)][device][cap];
        return validTimerange(allowed_period);
    }

    function setDevice(Proxy identity, address device, uint start_date, uint end_date) public {
        setCap(identity, device, CAP_FORWARD, start_date, end_date);
        setCap(identity, device, CAP_AUTH, start_date, end_date);
        setCap(identity, device, CAP_DEVICE_MANAGER, start_date, end_date);
    }

    function unregisterIdentity(Proxy identity) public checkCap(identity, CAP_ADMIN) {
        registered_identities[address(identity)] = false;
        emit IdentityUnregistered(address(identity));
    }

    function upgrade(Proxy identity, IdentityManager newIdentityManager) public checkCap(identity, CAP_ADMIN) {
        identity.addOwner(address(newIdentityManager));
        identity.renounce();
        newIdentityManager.registerIdentity(identity, msg.sender);
        unregisterIdentity(identity);
        emit Upgraded(address(this), address(newIdentityManager));
    }

    /// @dev Allows a user to transfer control of existing proxy to this contract. Must come through proxy
    /// @param owner Key who can use this contract to control proxy. Given full power
    /// Note: User must change owner of proxy to this contract after calling this
    function registerIdentity(Proxy identity, address owner) public {
        require(!registered_identities[address(identity)], "Already registered on that identity");
        registered_identities[address(identity)] = true;
        require(identity.isOwner(address(this)), "I'm not an owner of that identity");
        setFirstDevice(identity, owner, now, 0);
        emit IdentityRegistered(address(identity));
    }

    modifier checkCap(Proxy identity, string memory cap) {
        Timerange memory allowed_period = capabilities[address(identity)][msg.sender][cap];
        require(validTimerange(allowed_period), "Capability not allowed");
        _;
    }

    function validTimerange(Timerange memory timerange) private view returns (bool) {
        return timerange.start != 0 && timerange.start <= now && (now <= timerange.end || timerange.end == 0);
    }

    /// @dev Allows a user to forward a call through their proxy.
    function forwardTo(Proxy identity, address destination, uint value, bytes memory data) public checkCap(identity, CAP_FORWARD) {
        identity.forward(destination, value, data);
    }
}