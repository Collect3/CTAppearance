CTAppearance
============

`CTAppearance` is a clone of the native `UIAppearance` proxy.

It's current purpose is to provide an alternative to `UIAppearance` on iOS7. In iOS7 GM `UIAppearance` is currently very slow and is unusable for apps that make heavy use of this feature.

## Usage - Simple

Simply just include the CTAppearance files in your project. This will replace all use of `UIAppearance` with `CTAppearance`. By default any `appearance` or `appearanceWhenContainedIn` calls will use the ones provided by `CTAppearance`

## Usage - Custom

To avoid replacing all use of  `UIAppearance` define the macro 

```objective-c
#define CTAPPEARANCE_DISABLE_AUTO_INSTALL 1
````

and enable
```objective-c
[CTAppearance setEnabled: YES];
````

The appearance proxy can then be called using `appearanceCT` and `appearanceCTWhenContainedIn`
```objective-c
[[UILabel appearanceCT] setBackgroundColor: [UIColor redColor]];
[[UILabel appearanceCTWhenContainedIn: [UIView class], nil] setTextColor:[UIColor blueColor]];
````

## Limitations

WARNING: Does not currently respect properties that have been manually assigned.

So in the following case:

```objective-c
[[UILabel appearanceCT] setBackgroundColor: [UIColor redColor]];

UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(0,0,100,20)];
label.backgroundColor = [UIColor greenColor];
````
The label will remain redColor.


As the work currently happens in willMoveToSuperview, it's generally possible to make the modifications after addSubview like so:

```objective-c
[[UILabel appearanceCT] setBackgroundColor: [UIColor redColor]];

UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(0,0,100,20)];
[self addSubview: label];
label.backgroundColor = [UIColor greenColor];
````

The solutions I know about to fix / support this feature require a lot of swizzling hackery, and for our current use case was not worth the performance and stability trade off. But if anyone knows a good way of handling this functionality I'll be happy to accept your pull request or please let me know your ideas!

## Contact

[David Fumberger](http://github.com/djfumberger)
[@djfumberger](https://twitter.com/djfumberger)

## License
CTChromecast is available under the MIT license. See the LICENSE file for more info.
