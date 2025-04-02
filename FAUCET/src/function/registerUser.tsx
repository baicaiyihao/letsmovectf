import React, { useState } from "react";
import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { networkConfig } from "../config/networkConfig";

const Register: React.FC<{ onSuccess: () => void }> = ({ onSuccess }) => {
    const currentAccount = useCurrentAccount();
    const { mutateAsync: signAndExecute, isError } = useSignAndExecuteTransaction();
    const PackageChallenge = networkConfig.testnet.packageChallenge;
    const UserList = networkConfig.testnet.UserList;
    const Unuserlist = networkConfig.testnet.UncheckUserList;
    const [loading, setLoading] = useState(false);
    const [github_id, set_github_id] = useState("");
    const [email_hash, set_email_hash] = useState("");

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
                module: "user",
                function: "register_user",
                // typeArguments: [Faucet],
                arguments: [
                    tx.pure.option('string',email_hash),
                    tx.pure.option('string',github_id),
                    tx.object(UserList),
                    tx.object(Unuserlist),
                    tx.object(networkConfig.testnet.clock),
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
            placeholder="Enter github ID"
            value={github_id}
            onChange={(e) => set_github_id(e.target.value)} // 绑定输入事件
          />
          <input
            type="text"
            placeholder="Enter email hash"
            value={email_hash}
            onChange={(e) => set_email_hash(e.target.value)} // 绑定输入事件
          />
          <button
            onClick={create}
            disabled={!github_id || loading} // 禁用按钮直到输入了amount且不在加载状态
          >
              {loading ? 'Loading...' : 'register'}
          </button>
      </div>
    );
};

export default Register;



