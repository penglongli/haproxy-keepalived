package signals

import (
	"os"
	"os/signal"
	"syscall"
)

// SetupSignalHandler registered for SIGTERM SIGINT and SIGHUP.
// Stop channel is returned which is closed on SIGTERM and SIGINT
// Reload channel is returned when received SIGHUP
func SetupSignalHandler() (reloadCh <-chan struct{}, stopCh <-chan struct{}) {
	stop := make(chan struct{})
	reload := make(chan struct{})

	c := make(chan os.Signal)
	signal.Notify(c, signals...)
	go func() {
		for s := range c {
			if s == syscall.SIGHUP {
				reload <- struct{}{}
			} else {
				close(stop)
				break
			}
		}
	}()

	return reload, stop
}
