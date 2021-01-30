package server

import (
	"os"
	"os/exec"

	"k8s.io/klog"
)

type Options struct {
	haproxyPid     string
	haproxyCfg     string
	keepalivedConf string
}

func (o *Options) Run(stopCh <-chan struct{}) {
	rlCmd := o.startRsyslog()
	hpCmd, hpCh := o.startHAProxy()
	kaCmd, kaCh := o.startKeepvalied()

	klog.Infof("[main] haproxy-keepalived is started.")

	select {
	case err := <-hpCh:
		{
			klog.Warningf("[main] HAProxy is not running.")
			if err != nil {
				klog.Warningf("[main] Err: %s", err.Error())
			}
		}
	case err := <-kaCh:
		{
			klog.Warning("[main] Keepalived is not running")
			if err != nil {
				klog.Warningf("[main] Err: %s", err.Error())
			}
		}
	case <-stopCh:
		{
			klog.Warning("[main] Received terminal signal.")
		}
	}
	// Kill all the sub process whether it closed.
	if err := hpCmd.Process.Kill(); err != nil {
		klog.Error(err)
	}
	klog.Warning("HAProxy is killed.")

	if err := kaCmd.Process.Kill(); err != nil {
		klog.Error(err)
	}
	klog.Warning("Keepalived is killed.")
	if err := rlCmd.Process.Kill(); err != nil {
		klog.Error(err)
	}
	klog.Warning("Rsyslogd is killed.")
}

// startHAProxy will run HAProxy as subprocess.
func (o *Options) startHAProxy() (cmd *exec.Cmd, stopCh <-chan error) {
	klog.Infof("[main] HAProxy is starting>>>>>>>>>>>>>>>>>>>>>>>>>")

	// Pre clean-up keepalived.pid
	_ = os.Remove(o.haproxyPid)

	// Start HAProxy
	cmd = exec.Command("/usr/local/sbin/haproxy", "-p", o.haproxyPid,
		"-db", "-f", o.haproxyCfg, "-W")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	signalCh := make(chan error)
	if err := cmd.Start(); err != nil {
		klog.Error(err)
		close(signalCh)
	} else {
		// Wait for process finished.
		go func() {
			signalCh <- cmd.Wait()
		}()
	}
	return cmd, signalCh
}

// startKeepvalied will run Keepalived as subprocess
func (o *Options) startKeepvalied() (cmd *exec.Cmd, stopCh <-chan error) {
	klog.Infof("[main] Keepalived is starting>>>>>>>>>>>>>>>>>>>>>>>>>")

	// Pre clean-up keepalived.pid
	_ = os.Remove("/var/run/keepalived.pid")

	// Start Keepalived
	cmd = exec.Command("keepalived", "--dont-fork", "--dump-conf", "--log-console", "--log-detail",
		"--log-facility", "7", "--vrrp", "-f", o.keepalivedConf)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	signalCh := make(chan error)
	if err := cmd.Start(); err != nil {
		klog.Error(err)
		close(signalCh)
	} else {
		// Wait for process finished.
		go func() {
			signalCh <- cmd.Wait()
		}()
	}
	return cmd, signalCh
}

// startRsyslog will run Rsyslogd as subprocess.
func (o *Options) startRsyslog() (cmd *exec.Cmd) {
	klog.Infof("[main] Rsyslogd is starting>>>>>>>>>>>>>>>>>>>>>>>>>")
	cmd = exec.Command("rsyslogd")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	signalCh := make(chan error)
	if err := cmd.Start(); err != nil {
		klog.Error(err)
		close(signalCh)
	}
	return cmd
}
