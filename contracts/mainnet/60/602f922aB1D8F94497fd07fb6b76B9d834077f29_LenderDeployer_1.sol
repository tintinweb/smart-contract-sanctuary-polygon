/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

// hevm: flattened sources of src/deployers/LenderDeployer.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

////// src/factories/interfaces.sol
/* pragma solidity >=0.7.6; */

interface NAVFeedFactoryLike {
    function newFeed() external returns (address);
}

interface TitleFabLike {
    function newTitle(string calldata, string calldata) external returns (address);
}

interface PileFactoryLike {
    function newPile() external returns (address);
}

interface ShelfFactoryLike {
    function newShelf(address, address, address, address) external returns (address);
}

interface ReserveFactoryLike_1 {
    function newReserve(address) external returns (address);
}

interface AssessorFactoryLike_2 {
    function newAssessor() external returns (address);
}

interface TrancheFactoryLike_1 {
    function newTranche(address, address) external returns (address);
}

interface CoordinatorFactoryLike_2 {
    function newCoordinator(uint) external returns (address);
}

interface OperatorFactoryLike_1 {
    function newOperator(address) external returns (address);
}

interface MemberlistFactoryLike_1 {
    function newMemberlist() external returns (address);
}

interface RestrictedTokenFactoryLike_1 {
    function newRestrictedToken(string calldata, string calldata) external returns (address);
}

interface PoolAdminFactoryLike {
    function newPoolAdmin() external returns (address);
}

interface ClerkFactoryLike {
    function newClerk(address, address) external returns (address);
}

interface castenManagerFactoryLike {
    function newcastenManager(address, address, address,  address, address, address, address, address) external returns (address);
}


////// src/fixed_point.sol
/* pragma solidity >=0.7.6; */

abstract contract FixedPoint {
    struct Fixed27 {
        uint value;
    }
}

////// src/deployers/LenderDeployer.sol
/* pragma solidity >=0.7.6; */

/* import { ReserveFactoryLike, AssessorFactoryLike, TrancheFactoryLike, CoordinatorFactoryLike, OperatorFactoryLike, MemberlistFactoryLike, RestrictedTokenFactoryLike, PoolAdminFactoryLike, ClerkFactoryLike } from "./../factories/interfaces.sol"; */

/* import {FixedPoint}      from "./../fixed_point.sol"; */


interface DependLike_2 {
    function depend(bytes32, address) external;
}

interface AuthLike_2 {
    function rely(address) external;
    function deny(address) external;
}

interface MemberlistLike_3 {
    function updateMember(address, uint) external;
}

interface FileLike_2 {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, address value) external;
}

interface PoolAdminLike_1 {
    function rely(address) external;
}

contract LenderDeployer_1 is FixedPoint {
    address public immutable root;
    address public immutable currency;
    address public immutable memberAdmin;

    // factory contracts
    TrancheFactoryLike_1          public immutable trancheFactory;
    ReserveFactoryLike_1          public immutable reserveFactory;
    AssessorFactoryLike_2         public immutable assessorFactory;
    CoordinatorFactoryLike_2      public immutable coordinatorFactory;
    OperatorFactoryLike_1         public immutable operatorFactory;
    MemberlistFactoryLike_1       public immutable memberlistFactory;
    RestrictedTokenFactoryLike_1  public immutable restrictedTokenFactory;
    PoolAdminFactoryLike        public immutable poolAdminFactory;

    // lender state variables
    Fixed27             public minSeniorRatio;
    Fixed27             public maxSeniorRatio;
    uint                public maxReserve;
    uint                public challengeTime;
    Fixed27             public seniorInterestRate;


    // contract addresses
    address             public adapterDeployer;
    address             public assessor;
    address             public poolAdmin;
    address             public seniorTranche;
    address             public juniorTranche;
    address             public seniorOperator;
    address             public juniorOperator;
    address             public reserve;
    address             public coordinator;

    address             public seniorToken;
    address             public juniorToken;

    // token names
    string              public seniorName;
    string              public seniorSymbol;
    string              public juniorName;
    string              public juniorSymbol;
    // restricted token member list
    address             public seniorMemberlist;
    address             public juniorMemberlist;

    address             public deployer;
    bool public wired;

    address public memberList;

    constructor(address root_, address currency_, address trancheFactory_, address memberlistFactory_, address restrictedtokenFab_, address reserveFactory_, address assessorFactory_, address coordinatorFactory_, address operatorFactory_, address poolAdminFactory_, address memberAdmin_, address adapterDeployer_) {
        deployer = msg.sender;
        root = root_;
        currency = currency_;
        memberAdmin = memberAdmin_;
        adapterDeployer = adapterDeployer_;

        trancheFactory = TrancheFactoryLike_1(trancheFactory_);
        memberlistFactory = MemberlistFactoryLike_1(memberlistFactory_);
        restrictedTokenFactory = RestrictedTokenFactoryLike_1(restrictedtokenFab_);
        reserveFactory = ReserveFactoryLike_1(reserveFactory_);
        assessorFactory = AssessorFactoryLike_2(assessorFactory_);
        poolAdminFactory = PoolAdminFactoryLike(poolAdminFactory_);
        coordinatorFactory = CoordinatorFactoryLike_2(coordinatorFactory_);
        operatorFactory = OperatorFactoryLike_1(operatorFactory_);
    }

    function init(uint minSeniorRatio_, uint maxSeniorRatio_, uint maxReserve_, uint challengeTime_, uint seniorInterestRate_, string memory seniorName_, string memory seniorSymbol_, string memory juniorName_, string memory juniorSymbol_) public {
        require(msg.sender == deployer);
        challengeTime = challengeTime_;
        minSeniorRatio = Fixed27(minSeniorRatio_);
        maxSeniorRatio = Fixed27(maxSeniorRatio_);
        maxReserve = maxReserve_;
        seniorInterestRate = Fixed27(seniorInterestRate_);

        // token names
        seniorName = seniorName_;
        seniorSymbol = seniorSymbol_;
        juniorName = juniorName_;
        juniorSymbol = juniorSymbol_;

        deployer = address(1);
    }

    function deployJunior() public {
        require(juniorTranche == address(0) && deployer == address(1));
        juniorToken = restrictedTokenFactory.newRestrictedToken(juniorSymbol, juniorName);
        juniorTranche = trancheFactory.newTranche(currency, juniorToken);
        juniorMemberlist = memberlistFactory.newMemberlist();
        juniorOperator = operatorFactory.newOperator(juniorTranche);
        AuthLike_2(juniorMemberlist).rely(root);
        AuthLike_2(juniorToken).rely(root);
        AuthLike_2(juniorToken).rely(juniorTranche);
        AuthLike_2(juniorOperator).rely(root);
        AuthLike_2(juniorTranche).rely(root);
    }

    function deploySenior(address memberListAddr) public {
        require(seniorTranche == address(0) && deployer == address(1));
        seniorToken = restrictedTokenFactory.newRestrictedToken(seniorSymbol, seniorName);
        seniorTranche = trancheFactory.newTranche(currency, seniorToken);
        // seniorMemberlist = memberlistFactory.newMemberlist();
        seniorMemberlist = memberListAddr;
        seniorOperator = operatorFactory.newOperator(seniorTranche);
        AuthLike_2(seniorMemberlist).rely(root);
        AuthLike_2(seniorToken).rely(root);
        AuthLike_2(seniorToken).rely(seniorTranche);
        AuthLike_2(seniorOperator).rely(root);
        AuthLike_2(seniorTranche).rely(root);

        if (adapterDeployer != address(0)) {
            AuthLike_2(seniorTranche).rely(adapterDeployer);
            AuthLike_2(seniorMemberlist).rely(adapterDeployer);
        }
    }

    function deployReserve() public {
        require(reserve == address(0) && deployer == address(1));
        reserve = reserveFactory.newReserve(currency);
        AuthLike_2(reserve).rely(root);
        if (adapterDeployer != address(0)) AuthLike_2(reserve).rely(adapterDeployer);
    }

    function deployAssessor() public {
        require(assessor == address(0) && deployer == address(1));
        assessor = assessorFactory.newAssessor();
        AuthLike_2(assessor).rely(root);
        if (adapterDeployer != address(0)) AuthLike_2(assessor).rely(adapterDeployer);
    }

    function deployPoolAdmin() public {
        require(poolAdmin == address(0) && deployer == address(1));
        poolAdmin = poolAdminFactory.newPoolAdmin();
        PoolAdminLike_1(poolAdmin).rely(root);
        if (adapterDeployer != address(0)) PoolAdminLike_1(poolAdmin).rely(adapterDeployer);
    }

    function deployCoordinator() public {
        require(coordinator == address(0) && deployer == address(1));
        coordinator = coordinatorFactory.newCoordinator(challengeTime);
        AuthLike_2(coordinator).rely(root);
    }

    function deploy() public virtual {
        require(coordinator != address(0) && assessor != address(0) &&
                reserve != address(0) && seniorTranche != address(0));

        require(!wired, "lender contracts already wired"); // make sure lender contracts only wired once
        wired = true;

        // required depends
        // reserve
        AuthLike_2(reserve).rely(seniorTranche);
        AuthLike_2(reserve).rely(juniorTranche);
        AuthLike_2(reserve).rely(coordinator);
        AuthLike_2(reserve).rely(assessor);

        // tranches
        DependLike_2(seniorTranche).depend("reserve",reserve);
        DependLike_2(juniorTranche).depend("reserve",reserve);
        AuthLike_2(seniorTranche).rely(coordinator);
        AuthLike_2(juniorTranche).rely(coordinator);
        AuthLike_2(seniorTranche).rely(seniorOperator);
        AuthLike_2(juniorTranche).rely(juniorOperator);

        // coordinator implements epoch ticker interface
        DependLike_2(seniorTranche).depend("coordinator", coordinator);
        DependLike_2(juniorTranche).depend("coordinator", coordinator);

        //restricted token
        DependLike_2(seniorToken).depend("memberlist", seniorMemberlist);
        DependLike_2(juniorToken).depend("memberlist", juniorMemberlist);

        //allow casten contracts to hold SEN/JUN tokens
        MemberlistLike_3(juniorMemberlist).updateMember(juniorTranche, type(uint256).max);
        MemberlistLike_3(seniorMemberlist).updateMember(seniorTranche, type(uint256).max);

        // operator
        DependLike_2(seniorOperator).depend("tranche", seniorTranche);
        DependLike_2(juniorOperator).depend("tranche", juniorTranche);
        DependLike_2(seniorOperator).depend("token", seniorToken);
        DependLike_2(juniorOperator).depend("token", juniorToken);

        // coordinator
        DependLike_2(coordinator).depend("seniorTranche", seniorTranche);
        DependLike_2(coordinator).depend("juniorTranche", juniorTranche);
        DependLike_2(coordinator).depend("assessor", assessor);

        AuthLike_2(coordinator).rely(poolAdmin);

        // assessor
        DependLike_2(assessor).depend("seniorTranche", seniorTranche);
        DependLike_2(assessor).depend("juniorTranche", juniorTranche);
        DependLike_2(assessor).depend("reserve", reserve);

        AuthLike_2(assessor).rely(coordinator);
        AuthLike_2(assessor).rely(reserve);
        AuthLike_2(assessor).rely(poolAdmin);

        // poolAdmin
        DependLike_2(poolAdmin).depend("assessor", assessor);
        DependLike_2(poolAdmin).depend("juniorMemberlist", juniorMemberlist);
        DependLike_2(poolAdmin).depend("seniorMemberlist", seniorMemberlist);
        DependLike_2(poolAdmin).depend("coordinator", coordinator);

        AuthLike_2(juniorMemberlist).rely(poolAdmin);
        AuthLike_2(seniorMemberlist).rely(poolAdmin);

        if (memberAdmin != address(0)) AuthLike_2(juniorMemberlist).rely(memberAdmin);
        if (memberAdmin != address(0)) AuthLike_2(seniorMemberlist).rely(memberAdmin);

        FileLike_2(assessor).file("seniorInterestRate", seniorInterestRate.value);
        FileLike_2(assessor).file("maxReserve", maxReserve);
        FileLike_2(assessor).file("maxSeniorRatio", maxSeniorRatio.value);
        FileLike_2(assessor).file("minSeniorRatio", minSeniorRatio.value);
    }
}