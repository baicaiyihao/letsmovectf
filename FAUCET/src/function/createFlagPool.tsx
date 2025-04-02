import React, { useState } from "react";
import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { networkConfig } from "../config/networkConfig";

const CreateFlagPool: React.FC<{ onSuccess: () => void }> = ({ onSuccess }) => {
    const currentAccount = useCurrentAccount();
    const { mutateAsync: signAndExecute, isError } = useSignAndExecuteTransaction();
    const PackageChallenge = networkConfig.testnet.packageChallenge;
    const AdminCap = networkConfig.testnet.adminCap;
    const Faucet = networkConfig.testnet.PLEDGEX_FAUCET;
    const [loading, setLoading] = useState(false);
    const [num, setNum] = useState(100000);

    const create = async () => {
        if (!currentAccount?.address) {
            console.error("No connected account found.");
            return;
        }
        console.log("adress", currentAccount.address);
        setLoading(true);
        try {
            const tx = new Transaction();
            tx.setGasBudget(10000000);

            tx.moveCall({
                package: PackageChallenge,
                module: "challenge",
                function: "createFlagPool",
                typeArguments: [Faucet],
                arguments: [
                    tx.object(AdminCap),
                ],
            });
            const result = await signAndExecute({ transaction: tx });
            if (result && !isError) {
                onSuccess();
            }
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    return (
      <div style={{ display: 'flex', alignItems: 'center' }}>
          <input
            type="text"
            placeholder="Enter amount"
            value={num}
            onChange={(e) => setNum(Number(e.target.value))} // 绑定输入事件
          />
          <button
            onClick={create}
            disabled={!num || loading} // 禁用按钮直到输入了amount且不在加载状态
          >
              {loading ? 'Loading...' : 'createFlagPool'}
          </button>
      </div>
    );
};

export default CreateFlagPool;



