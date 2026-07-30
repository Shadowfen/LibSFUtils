A utility class to keep track of addOn-registered events, and make it easy to unregister them all.

The instance of the class is created with the addon name, which is used to register all tracked events under.

If you need to have multiple registrations of the same event (which need different names), then create multiple instances of EvtMgr, each with a different name.

## EvtMgr:New()
`function sfutil.EvtMgr:New(addonName)`

Create an instance of an EvtMgr.

## EvtMgr:registerEvt()
`function sfutil.EvtMgr:registerEvt(event, ...)`

Add an event to register for this addon, with the appropriate
parameters for it.

## EvtMgr:filterEvt()
`function sfutil.EvtMgr:filterEvt(event, ...)`

Add a filter for a registered event for this addon, with the appropriate
parameters for it.  (Note that filters are not tracked.)

## EvtMgr:registerUpdateEvt()
`function sfutil.EvtMgr:registerUpdateEvt(name, interval, callback, ...)`

Add an updating event to register for this addon, with the appropriate
parameters for it.

## EvtMgr:unregEvt()
`function sfutil.EvtMgr:unregEvt(event)`
Unregister (remove) a particular registered event for this addon.

Associated filters will also go away when the event is unregistered
by the game. Works with Update Events too.

## EvtMgr:unregUpdateEvt()
`function sfutil.EvtMgr:unregUpdateEvt(name)`

## EvtMgr:unregAllEvt()
`function sfutil.EvtMgr:unregAllEvt()`

Unregister ALL events currently tracked by this EvtMgr instance.

## EvtMgr:unregAllUpdateEvt()
`function sfutil.EvtMgr:unregAllUpdateEvt()`

Unregister ALL update events currently tracked by this EvtMgr instance.
