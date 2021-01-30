package server

import (
	"os/exec"

	"k8s.io/klog"
)

func checkProcessExist(process string) bool {
	cmd := exec.Command("pidof", process)
	if err := cmd.Start(); err != nil {
		klog.Errorf("[main] Check process %s exit failed, err: %s", err.Error())
	}
	if err := cmd.Wait(); err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			klog.Errorf("[main] Process %s exit code not 0, code: %d", exitError.ExitCode())
			return false
		}
	}
	return true
}
