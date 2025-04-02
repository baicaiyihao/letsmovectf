import {getFullnodeUrl, SuiClient} from "@mysten/sui/client";
import { createNetworkConfig } from "@mysten/dapp-kit";

const { networkConfig, useNetworkVariable, useNetworkVariables } =
  createNetworkConfig({
    devnet: {
      url: getFullnodeUrl("devnet"),
    },
    testnet: {
      url: getFullnodeUrl("testnet"),
        packageChallenge:"0xc4ed65bda7869db68da814ccc7a5928c895399afe6e817f3a2fc231c656cd7e2",
        adminCap:"0xdaf2bc522644df9535b7724cd961b72a5af710f05590b87f79a67c688d2295d1",
        PLEDGEX_FAUCET:"0xfdd285cfad8a4578218533d50dd72fe7ccc85b05facf8114fca9b70681d44436::pledgex::PLEDGEX",
        flag_pool:"0xe59484d0c52ad69a1f432d8698b9a2d62f01ef7e88dd564279a2c74e65d27862",
        UserList:"0x5ae813e81f5c51c266e79df84b8e6934ef729f871e74dd86e79c550ac962aa13",
        UncheckUserList:"0x08696ac1d7f964c574cb4035fdd4af61ed79e168ea9ed6ab88cc23958c8bb649",
        ChallengeTable:"0x4402bbc805b048c2e5c4f590e1d3ba5f92b7a78ce7f94dfee008fa6e8f1b8b23",
      clock:"0x6",
    },
    mainnet: {
      url: getFullnodeUrl("mainnet"),
    },
  });

const suiClient = new SuiClient({
    url:networkConfig.testnet.url,
})
export { useNetworkVariable, useNetworkVariables, networkConfig,suiClient };
