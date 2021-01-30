package server

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"k8s.io/klog"

	"github.com/penglongli/haproxy-keepalived/server/signals"
	"github.com/penglongli/haproxy-keepalived/version"
)

var (
	haproxyPidFile, haproxyCfgFile, keepalivedConfFile string
)

func NewCommand() *cobra.Command {
	rootCmd := &cobra.Command{
		Use:   "haproxy-keepalived",
		Short: "Start the application.",
		Run: func(cmd *cobra.Command, args []string) {
			o := &Options{
				haproxyPid:     haproxyPidFile,
				haproxyCfg:     haproxyCfgFile,
				keepalivedConf: keepalivedConfFile,
			}

			// Handle shutdown signals.
			reloadCh, stopCh := signals.SetupSignalHandler()

			// Handle reload for SIGHUP signal
			go func() {
				for range reloadCh {
					reload()
				}
			}()

			// Run
			o.Run(stopCh)
		},
	}
	reloadCmd := &cobra.Command{
		Use:   "reload",
		Short: "reload HAProxy process",
		Run: func(cmd *cobra.Command, args []string) {
			reload()
		},
	}
	versionCmd := &cobra.Command{
		Use:   "version",
		Short: "Print the version detail info.",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println(version.String())
		},
	}
	rootCmd.AddCommand(reloadCmd)
	rootCmd.AddCommand(versionCmd)

	rootCmd.PersistentFlags().StringVar(&haproxyPidFile, "haproxy-pid", "/run/haproxy.pid", "the pid filepath of HAProxy")
	rootCmd.PersistentFlags().StringVar(&haproxyCfgFile, "haproxy-cfg", "/usr/local/etc/haproxy/haproxy.cfg", "the config filepath of HAProxy")
	rootCmd.PersistentFlags().StringVar(&keepalivedConfFile, "keepalived-conf", "/etc/keepalived/keepalived.conf", "the config filepath of Keepalived")
	return rootCmd
}

func reload() {
	cmd := exec.Command("/bin/sh", "-c", "kill -SIGUSR2 $(pidof haproxy)")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Start(); err != nil {
		klog.Error(err)
	}
	if err := cmd.Wait(); err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			klog.Errorf("Exist code not 0, code: %d\n", exitError.ExitCode())
		}
	} else {
		klog.Infof("HAProxy Reloaded.")
	}
}
