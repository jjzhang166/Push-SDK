package org.anyrtc.PA.ui;

import android.content.Context;
import android.widget.TextView;

/**
 * Created by kanli on 12/20/16.
 */

public class AlwaysMarqueeTextView extends TextView {

    // com.duopin.app.AlwaysMaguequeScrollView
    public AlwaysMarqueeTextView(Context context) {

        super(context);

        // TODO Auto-generated constructor stub
    }


    @Override
    public boolean isFocused() {

        return true;

    }


}