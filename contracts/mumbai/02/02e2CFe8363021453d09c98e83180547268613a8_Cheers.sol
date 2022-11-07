// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './interfaces/ICheers.sol';
import './interfaces/IDaoPoolFactory.sol';
import './interfaces/IUserPoolFactory.sol';

contract Cheers is ICheers {
  // DAO_POOL_FACTORY
  address DAO_POOL_FACTORY_CONTRACT_ADDRESS = 0xa8474D6642a5C98E7BE8563E3D85e7FFa28805f7; // = usersDataコントラクトアドレス 先にUserDataコントラクトをdeploy
  IDaoPoolFactory public daoPoolFactory;
  // USER_POOL_FACTORY
  address USER_POOL_FACTORY_CONTRACT_ADDRESS = 0x25FbD1291de7CA6d89CfD054d9184051787fCCA8; // = usersDataコントラクトアドレス 先にUserDataコントラクトをdeploy
  IUserPoolFactory public userPoolFactory;

  constructor() {
    daoPoolFactory = IDaoPoolFactory(DAO_POOL_FACTORY_CONTRACT_ADDRESS);
    userPoolFactory = IUserPoolFactory(USER_POOL_FACTORY_CONTRACT_ADDRESS);
  }

  // DAOプール作成
  function newDaoPoolFactory(
    string memory _daoName,
    string memory _daoProfile,
    string memory _daoIcon
  ) public {
    daoPoolFactory.newDaoPoolFactory(msg.sender, _daoName, _daoProfile, _daoIcon);
  }

  // Userプール作成
  function newUserPoolFactory(
    string memory _userName,
    string memory _userProfile,
    string memory _userIcon
  ) public {
    userPoolFactory.newUserPoolFactory(msg.sender, _userName, _userProfile, _userIcon);
  }

  function setDaoPoolFactory(address daoPoolFactoryAddress) public {
    DAO_POOL_FACTORY_CONTRACT_ADDRESS = daoPoolFactoryAddress;
    daoPoolFactory = IDaoPoolFactory(daoPoolFactoryAddress);
  }

  function setUserPoolFactory(address userPoolFactoryAddress) public {
    USER_POOL_FACTORY_CONTRACT_ADDRESS = userPoolFactoryAddress;
    userPoolFactory = IUserPoolFactory(userPoolFactoryAddress);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUserPoolFactory {
  function newUserPoolFactory(
    address _userAddress,
    string memory _userName,
    string memory _userProfile,
    string memory _userIcon
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDaoPoolFactory {
  function newDaoPoolFactory(
    address _daoAddress,
    string memory _daoName,
    string memory _daoProfile,
    string memory _daoIcon
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICheers {}