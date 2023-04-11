// Contract that defines authority across the system and allows changes to it
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/access/IDAOAuthority.sol";

contract DAOAuthority is IDAOAuthority {

    Authorities authorities;

    address public collectionHelper;

    constructor(
        address _governor,
        address _policy,
        address _admin,
        address _forwarder,
        address _dispatcher,
        address _collectionHelper,
        address _collectionManager,
        address _tokenPriceCalculator
    ) {
        
        // Set the governor role
        authorities.governor = _governor;

        // Set the policy role
        authorities.policy = _policy;

        // Set the admin role
        authorities.admin = _admin;

        authorities.forwarder = _forwarder;

        authorities.dispatcher = _dispatcher;

        collectionHelper = _collectionHelper;

        authorities.collectionManager = _collectionManager;

        authorities.tokenPriceCalculator = _tokenPriceCalculator;
        
    }

    function changeGovernor(address _newGovernor) external {
        require(msg.sender == authorities.governor, "UNAUTHORIZED");
        authorities.governor = _newGovernor;
        emit ChangedGovernor(authorities.governor);
    }

    function changePolicy(address _newPolicy) external {
        require(msg.sender == authorities.governor, "UNAUTHORIZED");
        authorities.policy = _newPolicy;
        emit ChangedPolicy(authorities.policy);
    }

    function changeAdmin(address _newAdmin) external {
        require(msg.sender == authorities.governor, "UNAUTHORIZED");
        authorities.admin = _newAdmin;
        emit ChangedAdmin(authorities.admin);
    }

    function changeForwarder(address _newForwarder) external {
        require(msg.sender == authorities.governor, "UNAUTHORIZED");
        authorities.forwarder = _newForwarder;
        emit ChangedForwarder(authorities.forwarder);
    }

    function changeDispatcher(address _dispatcher) external {
        require(msg.sender == authorities.governor, "UNAUTHORIZED");
        authorities.dispatcher = _dispatcher;
        emit ChangedDispatcher(authorities.dispatcher);
    }

    function changeCollectionHelper(address _collectionHelper) external {
        require(msg.sender == authorities.governor, "UNAUTHORIZED");
        collectionHelper = _collectionHelper;
        emit ChangedCollectionHelper(collectionHelper);
    }

    function changeCollectionManager(address _collectionManager) external {
        require(msg.sender == authorities.governor, "UNAUTHORIZED");
        authorities.collectionManager = _collectionManager;
        emit ChangedCollectionManager(authorities.collectionManager);
    }

    function changeTokenPriceCalculator(address _tokenPriceCalculator) external {
        require(msg.sender == authorities.governor, "UNAUTHORIZED");
        authorities.tokenPriceCalculator = _tokenPriceCalculator;
        emit ChangedTokenPriceCalculator(authorities.tokenPriceCalculator);
    }

    function getAuthorities() public view returns(Authorities memory) {
        return authorities;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IDAOAuthority {

    /*********** EVENTS *************/
    event ChangedGovernor(address _newGovernor);
    event ChangedPolicy(address _newPolicy);
    event ChangedAdmin(address _newAdmin);
    event ChangedForwarder(address _newForwarder);
    event ChangedDispatcher(address _newDispatcher);
    event ChangedCollectionHelper(address _newCollectionHelper);
    event ChangedCollectionManager(address _newCollectionManager);
    event ChangedTokenPriceCalculator(address _newTokenPriceCalculator);

    struct Authorities {
        address governor;
        address policy;
        address admin;
        address forwarder;
        address dispatcher;
        address collectionManager;
        address tokenPriceCalculator;
    }

    function collectionHelper() external view returns(address);
    function getAuthorities() external view returns(Authorities memory);
}