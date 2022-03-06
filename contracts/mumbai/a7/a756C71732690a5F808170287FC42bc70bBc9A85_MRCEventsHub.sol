// SPDX-License-Identifier: UNLICENCED
/**
 * Copyright © All rights reserved 2022
 * Infinisoft Inc.
 * www.infini-soft.com
 */
pragma solidity ^0.8.10;

contract MRCEventsHub{
    mapping(uint256 => address) public topics;

    function createTopic(uint256 topic_, address topicContract) public {
        topics[topic_] = topicContract;
    }
}