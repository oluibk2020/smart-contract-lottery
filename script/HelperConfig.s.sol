//1. deploy mocks when we are on a local anvil chain
// keep track of contract address across different chains
//Sepolia ETH/USD
//Mainnet ETH/USD

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 * 1e18;
    uint96 public MOCK_GAS_PRICE_LINK = 1 * 1e9;
    int256 public MOCK_WEI_PER_UNIT_LINK = 4 * 1e15;
      address public FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    //LINK / ETH price
}


contract HelperConfig is CodeConstants, Script {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////

            TYPES
    //////////////////////////////////////////////////////////////*/

    struct NetworkConfig {
        uint256 subscriptionId;
        bytes32 gasLane;
         uint256 automationUpdateInterval;
        uint256 raffleEntranceFee;
        uint32 callbackGasLimit;
        uint256 interval;
        address vrfCoordinatorV2_5;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
         networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
    }

       function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

     function setConfig(uint256 chainId, NetworkConfig memory networkConfig) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinatorV2_5 != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

       function getMainnetEthConfig() public pure returns (NetworkConfig memory mainnetNetworkConfig) {
        mainnetNetworkConfig = NetworkConfig({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805,
            automationUpdateInterval: 30, // 30 seconds
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
    }

    //@dev https://docs.chain.link/vrf/v2-5/supported-networks
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        return sepoliaNetworkConfig({
            subscriptionId: 0,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            automationUpdateInterval: 30, // 30 secs
            raffleEntranceFee: 0.1 * 1e18,
            callbackGasLimit: 500_000, //500,000 gas
            vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinatorV2_5 != address(0)) {
            return localNetworkConfig;
        }

        console2.log(unicode"⚠️ You have deployed a mock conract!");
        console2.log("Make sure this was intentional");

        //deploy mocks
        //return the mock address
        vm.startBroadcast();
        //get mock price from mock file
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
            LinkToken link = new LinkToken();
            uint256 subscriptionId = vrfCoordinatorV2_5Mock.createSubscription();
        vm.stopBroadcast();

        //creating a variable with mockPrice
        localNetworkConfig = NetworkConfig({
           subscriptionId: subscriptionId,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            automationUpdateInterval: 30, // 30 seconds
            raffleEntranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: address(vrfCoordinatorV2_5Mock),
            link: address(link),
            account: FOUNDRY_DEFAULT_SENDER
        });
        vm.deal(localNetworkConfig.account, 100 ether);

        //returning the variable
        return localNetworkConfig;
    }
}